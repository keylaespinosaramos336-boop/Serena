package com.serena;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.WebServlet;
import java.io.*;
import java.sql.*;
import java.text.*;
import java.util.*;
import java.util.Date;

// ─── iText 7 para PDF ───
import com.itextpdf.kernel.pdf.*;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.colors.DeviceRgb;
import com.itextpdf.kernel.font.*;
import com.itextpdf.io.font.constants.StandardFonts;
import com.itextpdf.layout.*;
import com.itextpdf.layout.element.*;
import com.itextpdf.layout.properties.*;

/**
 * ReporteServlet — versión corregida.
 *
 * FIX principal (verPDF):
 *   Ahora guarda el nombre del archivo PDF en la columna `observaciones`
 *   junto al texto de quincena, separado por pipe "|".
 *   Al hacer verPDF?id=X, busca la fila con ese id y lee el nombre del archivo.
 *   Así cada reporte abre SU propio PDF y no siempre el más reciente.
 *
 * FIX secundario (generarPDF → INSERT):
 *   Guarda desempeño_promedio con ansiedadPromedio (no estresPromedio repetido).
 *   El campo observaciones ahora incluye el nombre del archivo:
 *     "Reporte quincenal generado. Quincena: INICIO a FIN|archivo.pdf"
 */
@WebServlet("/ReporteServlet")
public class ReporteServlet extends HttpServlet {

    private static final String DB_URL  = System.getenv().getOrDefault("DB_URL",
            "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC");
    private static final String DB_USER = System.getenv().getOrDefault("DB_USER", "root");
    private static final String DB_PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    private static final DeviceRgb AZUL_OSCURO = new DeviceRgb(30, 58, 95);
    private static final DeviceRgb AZUL_CLARO  = new DeviceRgb(74, 144, 217);
    private static final DeviceRgb VERDE        = new DeviceRgb(39, 174,  96);
    private static final DeviceRgb AMARILLO     = new DeviceRgb(243,156,  18);
    private static final DeviceRgb ROJO_COLOR   = new DeviceRgb(231, 76,  60);
    private static final DeviceRgb GRIS_FONDO   = new DeviceRgb(240,244, 248);

    private String pdfDir;

    @Override
    public void init() {
        pdfDir = getServletContext().getRealPath("/reportes_pdf/");
        new File(pdfDir).mkdirs();
    }

    // ════════════════════════════════════════════════════════════
    //  GET
    // ════════════════════════════════════════════════════════════
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // verPDF puede llamarlo también la empresa (sin sesión de psicólogo)
        String accion = req.getParameter("accion");
        if ("verPDF".equals(accion)) {
            verPDF(req, resp);
            return;
        }

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("idPsicologo") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }
        int idPsicologo = (Integer) session.getAttribute("idPsicologo");

        if (accion == null) accion = "";
        switch (accion) {
            case "listarEmpresas":   listarEmpresas(req, resp, idPsicologo);  break;
            case "datosPacientes":   datosPacientes(req, resp, idPsicologo);  break;
            case "historial":        historial(req, resp, idPsicologo);        break;
            default:
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Acción no reconocida");
        }
    }

    // ════════════════════════════════════════════════════════════
    //  POST
    // ════════════════════════════════════════════════════════════
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("idPsicologo") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }
        int idPsicologo = (Integer) session.getAttribute("idPsicologo");

        String accion = req.getParameter("accion");
        if (accion == null) accion = "";

        switch (accion) {
            case "guardarObservacion": guardarObservacion(req, resp, idPsicologo, session); break;
            case "generarPDF":         generarPDF(req, resp, idPsicologo, session);         break;
            default: resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
        }
    }

    // ════════════════════════════════════════════════════════════
    //  1. LISTAR EMPRESAS
    // ════════════════════════════════════════════════════════════
    private void listarEmpresas(HttpServletRequest req, HttpServletResponse resp, int idPsicologo)
            throws IOException {

        StringBuilder json = new StringBuilder("[");
        Connection con = null;
        try {
            con = getConexion();
            String sql =
                "SELECT DISTINCT e.id_empresa, e.nombre " +
                "FROM empresa e " +
                "JOIN usuario u ON u.id_empresa = e.id_empresa " +
                "JOIN cita c   ON c.id_usuario  = u.id_usuario " +
                "WHERE c.id_psicologo = ? AND c.fecha <= CURDATE() " +
                "  AND c.estado IN ('confirmada','pendiente') " +
                "ORDER BY e.nombre";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, idPsicologo);
            ResultSet rs = ps.executeQuery();
            boolean primero = true;
            while (rs.next()) {
                if (!primero) json.append(",");
                json.append("{\"id\":").append(rs.getInt("id_empresa"))
                    .append(",\"nombre\":\"").append(escaparJson(rs.getString("nombre"))).append("\"}");
                primero = false;
            }
            rs.close(); ps.close();
        } catch (Exception e) { e.printStackTrace(); }
        finally { cerrar(con); }
        json.append("]");
        writeJson(resp, json.toString());
    }

    // ════════════════════════════════════════════════════════════
    //  2. DATOS PACIENTES
    // ════════════════════════════════════════════════════════════
    private void datosPacientes(HttpServletRequest req, HttpServletResponse resp, int idPsicologo)
            throws IOException {

        int idEmpresa = intParam(req, "idEmpresa", 0);
        String inicio = req.getParameter("inicio");
        String fin    = req.getParameter("fin");

        if (idEmpresa == 0 || inicio == null || fin == null) {
            writeJson(resp, "{\"pacientes\":[]}");
            return;
        }

        StringBuilder json = new StringBuilder("{\"pacientes\":[");
        Connection con = null;
        try {
            con = getConexion();
            String sql =
                "SELECT u.id_usuario, u.nombre, " +
                "  IFNULL(AVG(a.estres),0)   AS estresAvg, " +
                "  IFNULL(AVG(a.ansiedad),0) AS ansiedadAvg, " +
                "  COUNT(DISTINCT DATE(a.fecha)) AS diasAuto, " +
                "  DATEDIFF(?, ?) + 1 AS diasQuincena, " +
                "  (SELECT COUNT(*) FROM cita c2 " +
                "   WHERE c2.id_usuario = u.id_usuario " +
                "     AND c2.id_psicologo = ? " +
                "     AND c2.fecha BETWEEN ? AND ? " +
                "     AND c2.fecha <= CURDATE() " +
                "     AND c2.estado IN ('confirmada','pendiente')) AS sesiones, " +
                "  (SELECT c3.id_cita FROM cita c3 " +
                "   WHERE c3.id_usuario = u.id_usuario " +
                "     AND c3.id_psicologo = ? " +
                "     AND c3.fecha <= CURDATE() " +
                "   ORDER BY c3.fecha DESC LIMIT 1) AS idUltimaCita " +
                "FROM usuario u " +
                "LEFT JOIN autoevaluacion a " +
                "  ON a.id_usuario = u.id_usuario " +
                "  AND DATE(a.fecha) BETWEEN ? AND ? " +
                "WHERE u.id_empresa = ? " +
                "  AND EXISTS ( " +
                "    SELECT 1 FROM cita cx " +
                "    WHERE cx.id_usuario = u.id_usuario " +
                "      AND cx.id_psicologo = ? " +
                "      AND cx.fecha BETWEEN ? AND ? " +
                "      AND cx.fecha <= CURDATE() " +
                "      AND cx.estado IN ('confirmada','pendiente') " +
                "  ) " +
                "GROUP BY u.id_usuario, u.nombre ORDER BY u.nombre";

            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, fin);   ps.setString(2, inicio);
            ps.setInt(3, idPsicologo); ps.setString(4, inicio); ps.setString(5, fin);
            ps.setInt(6, idPsicologo);
            ps.setString(7, inicio); ps.setString(8, fin);
            ps.setInt(9, idEmpresa);
            ps.setInt(10, idPsicologo); ps.setString(11, inicio); ps.setString(12, fin);

            ResultSet rs = ps.executeQuery();
            boolean primero = true;
            while (rs.next()) {
                int    diasQ   = rs.getInt("diasQuincena");
                int    diasA   = rs.getInt("diasAuto");
                double estres  = rs.getDouble("estresAvg");
                double ansiedad= rs.getDouble("ansiedadAvg");
                int    ses     = rs.getInt("sesiones");
                int    idCita  = rs.getInt("idUltimaCita");
                int    din     = diasQ > 0 ? Math.min((int) Math.round(diasA * 100.0 / diasQ), 100) : 0;

                if (!primero) json.append(",");
                json.append("{")
                    .append("\"idUsuario\":").append(rs.getInt("id_usuario")).append(",")
                    .append("\"nombre\":\"").append(escaparJson(rs.getString("nombre"))).append("\",")
                    .append("\"estresAvg\":").append(String.format("%.1f", estres)).append(",")
                    .append("\"ansiedadAvg\":").append(String.format("%.1f", ansiedad)).append(",")
                    .append("\"dinamicas\":").append(din).append(",")
                    .append("\"sesiones\":").append(ses).append(",")
                    .append("\"idUltimaCita\":").append(idCita)
                    .append("}");
                primero = false;
            }
            rs.close(); ps.close();
        } catch (Exception e) { e.printStackTrace(); }
        finally { cerrar(con); }
        json.append("]}");
        writeJson(resp, json.toString());
    }

    // ════════════════════════════════════════════════════════════
    //  3. GUARDAR OBSERVACIÓN (en cita.observaciones, NO en historial)
    // ════════════════════════════════════════════════════════════
    private void guardarObservacion(HttpServletRequest req, HttpServletResponse resp,
                                    int idPsicologo, HttpSession session) throws IOException {
        String obs    = req.getParameter("observacion");
        int    idCita = intParam(req, "idCita", 0);

        if (obs == null || obs.trim().isEmpty()) {
            session.setAttribute("reporteError", "La observación no puede estar vacía.");
            resp.sendRedirect(req.getContextPath() + "/pages/reportes.jsp"); return;
        }
        if (idCita == 0) {
            session.setAttribute("reporteError", "No se encontró la cita asociada.");
            resp.sendRedirect(req.getContextPath() + "/pages/reportes.jsp"); return;
        }

        Connection con = null;
        try {
            con = getConexion();
            asegurarColumnaObservaciones(con);
            String sql = "UPDATE cita SET observaciones = ? WHERE id_cita = ? AND id_psicologo = ?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, obs.trim()); ps.setInt(2, idCita); ps.setInt(3, idPsicologo);
            int filas = ps.executeUpdate(); ps.close();
            if (filas > 0) session.setAttribute("reporteExito", "Observación guardada correctamente.");
            else           session.setAttribute("reporteError", "No se pudo guardar: verifica que la cita sea tuya.");
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("reporteError", "Error al guardar: " + e.getMessage());
        } finally { cerrar(con); }
        resp.sendRedirect(req.getContextPath() + "/pages/reportes.jsp");
    }

    private void asegurarColumnaObservaciones(Connection con) {
        try {
            DatabaseMetaData meta = con.getMetaData();
            ResultSet cols = meta.getColumns(null, null, "cita", "observaciones");
            boolean existe = cols.next(); cols.close();
            if (!existe) {
                Statement st = con.createStatement();
                st.execute("ALTER TABLE cita ADD COLUMN observaciones TEXT NULL");
                st.close();
            }
        } catch (Exception e) { e.printStackTrace(); }
    }

    // ════════════════════════════════════════════════════════════
    //  4. GENERAR PDF  ← FIX: guarda nombre archivo en observaciones
    // ════════════════════════════════════════════════════════════
    private void generarPDF(HttpServletRequest req, HttpServletResponse resp,
                            int idPsicologo, HttpSession session) throws IOException {

        String nombreEmpresa    = param(req, "nombreEmpresa",    "Empresa");
        int    idEmpresa        = intParam(req, "idEmpresa",     0);
        String inicio           = param(req, "quincenaInicio",   "");
        String fin              = param(req, "quincenaFin",      "");
        String recomendaciones  = param(req, "recomendaciones",  "");
        double estresPromedio   = doubleParam(req, "estresPromedio",   0);
        double ansiedadPromedio = doubleParam(req, "ansiedadPromedio", 0);
        int    totalPacientes   = intParam(req, "totalPacientes",      0);

        String nombrePsicologo  = (String) session.getAttribute("nombreUsuario");
        if (nombrePsicologo == null) nombrePsicologo = "Dr./Dra.";

        // Datos del reporte anterior (para comparativa en el PDF)
        double estresAnterior   = 0;
        double ansiedadAnterior = 0;
        Connection con = null;
        try {
            con = getConexion();
            // FIX: excluir el reporte que se está generando (aún no insertado)
            String sqlPrev =
                "SELECT estres_promedio, desempeño_promedio FROM reporte_quincenal " +
                "WHERE id_empresa = ? AND id_psicologo = ? " +
                "AND recomendaciones IS NOT NULL AND recomendaciones != '' " +
                "ORDER BY fecha DESC LIMIT 1";
            PreparedStatement ps = con.prepareStatement(sqlPrev);
            ps.setInt(1, idEmpresa); ps.setInt(2, idPsicologo);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                estresAnterior   = rs.getDouble("estres_promedio")   / 10.0;
                ansiedadAnterior = rs.getDouble("desempeño_promedio") / 10.0;
            }
            rs.close(); ps.close();
        } catch (Exception e) { e.printStackTrace(); }
        finally { cerrar(con); }

        // Nombre del archivo incluye el id de empresa y timestamp para ser único
        String nombreArchivo = "reporte_" + idEmpresa + "_" + System.currentTimeMillis() + ".pdf";
        String rutaCompleta  = pdfDir + File.separator + nombreArchivo;

        try {
            construirPDF(rutaCompleta, nombreEmpresa, inicio, fin, nombrePsicologo,
                         totalPacientes, estresPromedio, ansiedadPromedio,
                         estresAnterior, ansiedadAnterior, recomendaciones);
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("reporteError", "Error generando el PDF: " + e.getMessage());
            resp.sendRedirect(req.getContextPath() + "/pages/reportes.jsp");
            return;
        }

        // ── FIX: guardar nombre del archivo en observaciones para recuperarlo después ──
        // Formato: "Quincena: INICIO a FIN|nombreArchivo.pdf"
        String obsConArchivo = "Reporte quincenal generado. Quincena: " + inicio + " a " + fin
                               + "|" + nombreArchivo;

        try {
            con = getConexion();
            String sqlIns =
                "INSERT INTO reporte_quincenal " +
                "(observaciones, recomendaciones, estres_promedio, desempeño_promedio, fecha, id_psicologo, id_empresa) " +
                "VALUES (?, ?, ?, ?, NOW(), ?, ?)";
            PreparedStatement ps = con.prepareStatement(sqlIns);
            ps.setString(1, obsConArchivo);
            ps.setString(2, recomendaciones);
            ps.setInt(3, (int) Math.round(estresPromedio   * 10));   // escala 0-100
            ps.setInt(4, (int) Math.round(ansiedadPromedio * 10));   // FIX: era estresPromedio otra vez
            ps.setInt(5, idPsicologo);
            ps.setInt(6, idEmpresa);
            ps.executeUpdate(); ps.close();
        } catch (Exception e) { e.printStackTrace(); }
        finally { cerrar(con); }

        // Enviar el PDF al cliente
        File archivoPDF = new File(rutaCompleta);
        if (archivoPDF.exists()) {
            resp.setContentType("application/pdf");
            resp.setHeader("Content-Disposition", "inline; filename=\"" + nombreArchivo + "\"");
            resp.setContentLength((int) archivoPDF.length());
            try (FileInputStream fis = new FileInputStream(archivoPDF);
                 OutputStream out = resp.getOutputStream()) {
                byte[] buf = new byte[4096];
                int n;
                while ((n = fis.read(buf)) != -1) out.write(buf, 0, n);
            }
        } else {
            session.setAttribute("reporteError", "El PDF no pudo generarse.");
            resp.sendRedirect(req.getContextPath() + "/pages/reportes.jsp");
        }
    }

    // ════════════════════════════════════════════════════════════
    //  5. HISTORIAL (JSON para reportes.jsp del psicólogo)
    // ════════════════════════════════════════════════════════════
    private void historial(HttpServletRequest req, HttpServletResponse resp, int idPsicologo)
            throws IOException {

        StringBuilder json = new StringBuilder("{\"reportes\":[");
        Connection con = null;
        try {
            con = getConexion();
            String sql =
                "SELECT rq.id_reporte, e.nombre AS empresa, " +
                "       DATE_FORMAT(rq.fecha,'%d/%m/%Y') AS fecha, " +
                "       rq.observaciones " +
                "FROM reporte_quincenal rq " +
                "JOIN empresa e ON rq.id_empresa = e.id_empresa " +
                "WHERE rq.id_psicologo = ? " +
                "  AND rq.recomendaciones IS NOT NULL AND rq.recomendaciones != '' " +
                "ORDER BY rq.fecha DESC LIMIT 20";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, idPsicologo);
            ResultSet rs = ps.executeQuery();
            boolean primero = true;
            while (rs.next()) {
                if (!primero) json.append(",");
                String obs = rs.getString("observaciones");
                // Extraer la quincena del texto guardado (antes del pipe)
                String quincena = "—";
                if (obs != null && obs.contains("Quincena:")) {
                    String parte = obs.split("\\|")[0];
                    quincena = parte.replace("Reporte quincenal generado. Quincena:", "").trim();
                }
                json.append("{")
                    .append("\"id\":").append(rs.getInt("id_reporte")).append(",")
                    .append("\"empresa\":\"").append(escaparJson(rs.getString("empresa"))).append("\",")
                    .append("\"fecha\":\"").append(escaparJson(rs.getString("fecha"))).append("\",")
                    .append("\"quincena\":\"").append(escaparJson(quincena)).append("\"")
                    .append("}");
                primero = false;
            }
            rs.close(); ps.close();
        } catch (Exception e) { e.printStackTrace(); }
        finally { cerrar(con); }
        json.append("]}");
        writeJson(resp, json.toString());
    }

    // ════════════════════════════════════════════════════════════
    //  6. VER PDF  ← FIX PRINCIPAL: usa el id_reporte para encontrar el archivo correcto
    // ════════════════════════════════════════════════════════════
    private void verPDF(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int id = intParam(req, "id", 0);

        if (id <= 0) {
            resp.sendError(404, "ID de reporte inválido");
            return;
        }

        // FIX: buscar en BD el nombre del archivo guardado para ESTE id_reporte específico
        String nombreArchivo = null;
        Connection con = null;
        try {
            con = getConexion();
            String sql = "SELECT observaciones FROM reporte_quincenal WHERE id_reporte = ?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String obs = rs.getString("observaciones");
                if (obs != null && obs.contains("|")) {
                    // El nombre del archivo está después del pipe
                    String[] partes = obs.split("\\|", 2);
                    if (partes.length == 2 && partes[1].endsWith(".pdf")) {
                        nombreArchivo = partes[1].trim();
                    }
                }
            }
            rs.close(); ps.close();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            cerrar(con);
        }

        File archivoPDF = null;

        // Si encontramos el nombre exacto, lo usamos directamente
        if (nombreArchivo != null) {
            archivoPDF = new File(pdfDir + File.separator + nombreArchivo);
        }

        // Fallback: si el archivo no existe en disco (servidor reiniciado, etc.)
        // buscar el más reciente que empiece con "reporte_idEmpresa_"
        if (archivoPDF == null || !archivoPDF.exists()) {
            File dir = new File(pdfDir);
            File[] todos = dir.listFiles(new FilenameFilter() {
                public boolean accept(File d, String name) {
                    return name.startsWith("reporte_") && name.endsWith(".pdf");
                }
            });
            if (todos != null && todos.length > 0) {
                Arrays.sort(todos, new Comparator<File>() {
                    public int compare(File a, File b) {
                        return Long.compare(b.lastModified(), a.lastModified());
                    }
                });
                archivoPDF = todos[0];
            }
        }

        if (archivoPDF != null && archivoPDF.exists()) {
            resp.setContentType("application/pdf");
            resp.setHeader("Content-Disposition", "inline; filename=\"" + archivoPDF.getName() + "\"");
            resp.setContentLength((int) archivoPDF.length());
            try (FileInputStream fis = new FileInputStream(archivoPDF);
                 OutputStream out = resp.getOutputStream()) {
                byte[] buf = new byte[4096];
                int n;
                while ((n = fis.read(buf)) != -1) out.write(buf, 0, n);
            }
        } else {
            resp.sendError(404, "PDF no encontrado. Es posible que el servidor haya sido reiniciado.");
        }
    }

    // ════════════════════════════════════════════════════════════
    //  PDF BUILDER (iText 7) — sin cambios funcionales
    // ════════════════════════════════════════════════════════════
    private void construirPDF(String ruta, String empresa, String inicio, String fin,
                               String psicologo, int totalPacientes,
                               double estresActual, double ansiedadActual,
                               double estresAnterior, double ansiedadAnterior,
                               String recomendaciones) throws Exception {

        PdfWriter   writer   = new PdfWriter(ruta);
        PdfDocument pdfDoc   = new PdfDocument(writer);
        Document    document = new Document(pdfDoc);
        document.setMargins(36, 36, 36, 36);

        PdfFont bold   = PdfFontFactory.createFont(StandardFonts.HELVETICA_BOLD);
        PdfFont normal = PdfFontFactory.createFont(StandardFonts.HELVETICA);

        // ENCABEZADO
        Table encabezado = new Table(UnitValue.createPercentArray(new float[]{1, 2}))
                .setWidth(UnitValue.createPercentValue(100));
        encabezado.addCell(new Cell().setBorder(com.itextpdf.layout.borders.Border.NO_BORDER)
                .add(new Paragraph("SERENA").setFont(bold).setFontSize(20).setFontColor(AZUL_OSCURO)));
        encabezado.addCell(new Cell().setBorder(com.itextpdf.layout.borders.Border.NO_BORDER)
                .setTextAlignment(TextAlignment.RIGHT)
                .add(new Paragraph("REPORTE DE BIENESTAR QUINCENAL").setFont(bold).setFontSize(11).setFontColor(AZUL_OSCURO))
                .add(new Paragraph(empresa).setFont(bold).setFontSize(14).setFontColor(AZUL_CLARO))
                .add(new Paragraph("Periodo: " + inicio + "  a  " + fin)
                        .setFont(normal).setFontSize(9).setFontColor(new DeviceRgb(100, 120, 140))));
        document.add(encabezado);

        document.add(new com.itextpdf.layout.element.LineSeparator(
                new com.itextpdf.kernel.pdf.canvas.draw.SolidLine())
                .setStrokeColor(AZUL_CLARO).setMarginTop(8).setMarginBottom(10));

        // INFORMACIÓN GENERAL
        document.add(new Paragraph("INFORMACION GENERAL")
                .setFont(bold).setFontSize(10).setFontColor(AZUL_OSCURO)
                .setBackgroundColor(GRIS_FONDO).setPadding(6).setMarginBottom(4));

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm", new Locale("es", "MX"));
        String fechaGeneracion = sdf.format(new Date());

        Table infoTable = new Table(UnitValue.createPercentArray(new float[]{1, 1, 1}))
                .setWidth(UnitValue.createPercentValue(100)).setMarginBottom(10);
        agregarInfoCelda(infoTable, bold, normal, "Psicologo", psicologo);
        agregarInfoCelda(infoTable, bold, normal, "Empresa",   empresa);
        agregarInfoCelda(infoTable, bold, normal, "Generado",  fechaGeneracion);
        document.add(infoTable);

        // KPIs
        document.add(new Paragraph("INDICADORES DE BIENESTAR (KPIs)")
                .setFont(bold).setFontSize(10).setFontColor(AZUL_OSCURO)
                .setBackgroundColor(GRIS_FONDO).setPadding(6).setMarginBottom(6));

        Table kpiTable = new Table(UnitValue.createPercentArray(new float[]{1, 1, 1}))
                .setWidth(UnitValue.createPercentValue(100)).setMarginBottom(10);
        agregarKPICard(kpiTable, bold, normal, "Pacientes atendidos", String.valueOf(totalPacientes), "", AZUL_CLARO);
        agregarKPICard(kpiTable, bold, normal, "Estres promedio",
                estresActual + "/10",
                estresAnterior > 0 ? "Anterior: " + estresAnterior + "/10" : "Primer periodo",
                colorKPI(estresActual));
        agregarKPICard(kpiTable, bold, normal, "Ansiedad promedio",
                ansiedadActual + "/10",
                ansiedadAnterior > 0 ? "Anterior: " + ansiedadAnterior + "/10" : "Primer periodo",
                colorKPI(ansiedadActual));
        document.add(kpiTable);

        // COMPARATIVA
        if (estresAnterior > 0 || ansiedadAnterior > 0) {
            document.add(new Paragraph("COMPARATIVA QUINCENA ACTUAL vs ANTERIOR")
                    .setFont(bold).setFontSize(10).setFontColor(AZUL_OSCURO)
                    .setBackgroundColor(GRIS_FONDO).setPadding(6).setMarginBottom(6));

            Table grafico = new Table(UnitValue.createPercentArray(new float[]{2, 3, 3}))
                    .setWidth(UnitValue.createPercentValue(100)).setMarginBottom(10);
            grafico.addHeaderCell(new Cell().add(new Paragraph("Indicador").setFont(bold).setFontSize(9))
                    .setBackgroundColor(AZUL_OSCURO).setFontColor(ColorConstants.WHITE));
            grafico.addHeaderCell(new Cell().add(new Paragraph("Actual").setFont(bold).setFontSize(9)
                    .setFontColor(ColorConstants.WHITE)).setBackgroundColor(AZUL_OSCURO));
            grafico.addHeaderCell(new Cell().add(new Paragraph("Anterior").setFont(bold).setFontSize(9)
                    .setFontColor(ColorConstants.WHITE)).setBackgroundColor(AZUL_OSCURO));

            agregarFilaGrafico(grafico, bold, normal, "Estres",   estresActual,   estresAnterior);
            agregarFilaGrafico(grafico, bold, normal, "Ansiedad", ansiedadActual, ansiedadAnterior);
            document.add(grafico);
        }

        // RECOMENDACIONES
        document.add(new Paragraph("RECOMENDACIONES PARA LA EMPRESA")
                .setFont(bold).setFontSize(10).setFontColor(AZUL_OSCURO)
                .setBackgroundColor(GRIS_FONDO).setPadding(6).setMarginBottom(6));
        document.add(new Paragraph(recomendaciones)
                .setFont(normal).setFontSize(10)
                .setBorder(new com.itextpdf.layout.borders.SolidBorder(AZUL_CLARO, 1f))
                .setPadding(10).setMarginBottom(14)
                .setFontColor(new DeviceRgb(40, 55, 71)));

        // PIE
        document.add(new com.itextpdf.layout.element.LineSeparator(
                new com.itextpdf.kernel.pdf.canvas.draw.DashedLine())
                .setStrokeColor(new DeviceRgb(200, 210, 220)).setMarginTop(10).setMarginBottom(6));
        document.add(new Paragraph("Este reporte es confidencial y generado por la plataforma Serena  " + fechaGeneracion)
                .setFont(normal).setFontSize(8).setFontColor(new DeviceRgb(150, 160, 170))
                .setTextAlignment(TextAlignment.CENTER));

        document.close();
    }

    // ── helpers PDF ───────────────────────────────────────────
    private void agregarInfoCelda(Table t, PdfFont bold, PdfFont normal, String etiqueta, String valor) {
        t.addCell(new Cell().setBorder(com.itextpdf.layout.borders.Border.NO_BORDER)
                .add(new Paragraph(etiqueta).setFont(bold).setFontSize(8).setFontColor(new DeviceRgb(100,120,140)))
                .add(new Paragraph(valor != null ? valor : "—").setFont(normal).setFontSize(10).setFontColor(new DeviceRgb(30,58,95))));
    }

    private void agregarKPICard(Table t, PdfFont bold, PdfFont normal, String titulo, String valor, String sub, DeviceRgb color) {
        t.addCell(new Cell().setBackgroundColor(new DeviceRgb(240,244,248)).setPadding(8)
                .add(new Paragraph(titulo).setFont(bold).setFontSize(8).setFontColor(new DeviceRgb(100,120,140)))
                .add(new Paragraph(valor).setFont(bold).setFontSize(16).setFontColor(color))
                .add(sub.isEmpty() ? new Paragraph("") : new Paragraph(sub).setFont(normal).setFontSize(8).setFontColor(new DeviceRgb(150,160,170))));
    }

    private void agregarFilaGrafico(Table t, PdfFont bold, PdfFont normal, String indicador, double actual, double anterior) {
        t.addCell(new Cell().add(new Paragraph(indicador).setFont(bold).setFontSize(9)));
        t.addCell(new Cell().setBackgroundColor(colorKPI(actual))
                .add(new Paragraph(actual + "/10").setFont(bold).setFontSize(10).setFontColor(ColorConstants.WHITE)));
        t.addCell(new Cell().setBackgroundColor(new DeviceRgb(220,230,240))
                .add(new Paragraph(anterior > 0 ? anterior + "/10" : "N/A").setFont(normal).setFontSize(9)));
    }

    private DeviceRgb colorKPI(double val) {
        if (val >= 7) return ROJO_COLOR;
        if (val >= 4) return AMARILLO;
        return VERDE;
    }

    // ════════════════════════════════════════════════════════════
    //  UTILIDADES
    // ════════════════════════════════════════════════════════════
    private Connection getConexion() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    private void cerrar(Connection con) {
        try { if (con != null) con.close(); } catch (Exception ignored) {}
    }

    private void writeJson(HttpServletResponse resp, String json) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().write(json);
    }

    private String escaparJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }

    private String param(HttpServletRequest req, String name, String def) {
        String v = req.getParameter(name);
        return (v != null && !v.trim().isEmpty()) ? v.trim() : def;
    }

    private int intParam(HttpServletRequest req, String name, int def) {
        try { return Integer.parseInt(req.getParameter(name)); }
        catch (Exception e) { return def; }
    }

    private double doubleParam(HttpServletRequest req, String name, double def) {
        try { return Double.parseDouble(req.getParameter(name)); }
        catch (Exception e) { return def; }
    }
}
