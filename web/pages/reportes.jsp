<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%
    // ── SESIÓN ──────────────────────────────────────────────────
    String nombreCompleto = (String) session.getAttribute("nombreUsuario");
    Integer idPsicologoSession = (Integer) session.getAttribute("idPsicologo");
    if (idPsicologoSession == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    int idPsicologo = idPsicologoSession;
    String primerNombre = (nombreCompleto != null && !nombreCompleto.trim().isEmpty())
                          ? nombreCompleto.trim().split(" ")[0] : "Psicólogo";

    // ── MENSAJES ─────────────────────────────────────────────────
    String msgExito = (String) session.getAttribute("reporteExito");
    String msgError = (String) session.getAttribute("reporteError");
    session.removeAttribute("reporteExito");
    session.removeAttribute("reporteError");

    // ── PARÁMETROS GET ───────────────────────────────────────────
    String empresaSelId  = request.getParameter("idEmpresa");
    String empresaSelNom = request.getParameter("nomEmpresa");
    String qInicio       = request.getParameter("inicio");
    String qFin          = request.getParameter("fin");

    // ── DB CONFIG ────────────────────────────────────────────────
    String DB_URL  = System.getenv().getOrDefault("DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC");
    String DB_USER = System.getenv().getOrDefault("DB_USER", "root");
    String DB_PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    // ── ESTRUCTURAS DE DATOS ─────────────────────────────────────
    List<Map<String,String>> listaEmpresas  = new ArrayList<>();
    List<Map<String,String>> listaPacientes = new ArrayList<>();
    List<Map<String,String>> listaReportes  = new ArrayList<>();
    double estresGrupal   = 0;
    double ansiedadGrupal = 0;
    int    totalAtendidos = 0;

    // ── Calcular quincena por defecto ─────────────────────────────
    if (qInicio == null || qInicio.isEmpty()) {
        Calendar cal = Calendar.getInstance();
        int dia  = cal.get(Calendar.DAY_OF_MONTH);
        int mes  = cal.get(Calendar.MONTH);
        int anio = cal.get(Calendar.YEAR);
        if (dia >= 16) {
            qInicio = String.format("%04d-%02d-16", anio, mes + 1);
            Calendar finMes = (Calendar) cal.clone();
            finMes.set(anio, mes, 1);
            finMes.add(Calendar.MONTH, 1);
            finMes.add(Calendar.DAY_OF_MONTH, -1);
            qFin = String.format("%04d-%02d-%02d", anio, mes + 1, finMes.get(Calendar.DAY_OF_MONTH));
        } else {
            qInicio = String.format("%04d-%02d-01", anio, mes + 1);
            qFin    = String.format("%04d-%02d-15", anio, mes + 1);
        }
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        String joinEmpresa;
        try {
            DatabaseMetaData meta = con.getMetaData();
            ResultSet cols = meta.getColumns(null, null, "usuario", "id_empresa");
            joinEmpresa = cols.next()
                ? "JOIN usuario u ON u.id_empresa = e.id_empresa"
                : "JOIN usuario u ON u.codigo_empresa = e.codigo_empresa";
            cols.close();
        } catch (Exception exMeta) {
            joinEmpresa = "JOIN usuario u ON u.codigo_empresa = e.codigo_empresa";
        }

        // ── 1. EMPRESAS ──────────────────────────────────────────
        String sqlEmp =
            "SELECT DISTINCT e.id_empresa, e.nombre " +
            "FROM empresa e " + joinEmpresa + " " +
            "JOIN cita c ON c.id_usuario = u.id_usuario " +
            "WHERE c.id_psicologo = ? AND c.fecha <= CURDATE() ORDER BY e.nombre";
        ps = con.prepareStatement(sqlEmp);
        ps.setInt(1, idPsicologo);
        rs = ps.executeQuery();
        while (rs.next()) {
            Map<String,String> emp = new HashMap<>();
            emp.put("id",     rs.getString("id_empresa"));
            emp.put("nombre", rs.getString("nombre"));
            listaEmpresas.add(emp);
        }
        rs.close(); ps.close();

        if ((empresaSelId == null || empresaSelId.isEmpty()) && !listaEmpresas.isEmpty()) {
            empresaSelId  = listaEmpresas.get(0).get("id");
            empresaSelNom = listaEmpresas.get(0).get("nombre");
        }

        // ── 2. PACIENTES ─────────────────────────────────────────
        if (empresaSelId != null && !empresaSelId.isEmpty()) {
            String sqlPac =
                "SELECT u.id_usuario, u.nombre, " +
                "  COALESCE(AVG(a.estres),  0) AS estresAvg, " +
                "  COALESCE(AVG(a.ansiedad),0) AS ansiedadAvg, " +
                "  COUNT(DISTINCT DATE(a.fecha)) AS diasAuto, " +
                "  DATEDIFF(?, ?) + 1 AS diasQuincena, " +
                "  (SELECT COUNT(*) FROM cita c2 WHERE c2.id_usuario = u.id_usuario " +
                "     AND c2.id_psicologo = ? AND c2.fecha BETWEEN ? AND ? " +
                "     AND c2.fecha <= CURDATE()) AS sesiones, " +
                "  (SELECT c3.id_cita FROM cita c3 WHERE c3.id_usuario = u.id_usuario " +
                "     AND c3.id_psicologo = ? AND c3.fecha <= CURDATE() " +
                "   ORDER BY c3.fecha DESC LIMIT 1) AS idUltimaCita " +
                "FROM empresa e " + joinEmpresa + " " +
                "LEFT JOIN autoevaluacion a ON a.id_usuario = u.id_usuario " +
                "  AND DATE(a.fecha) BETWEEN ? AND ? " +
                "WHERE e.id_empresa = ? " +
                "  AND EXISTS (SELECT 1 FROM cita cx WHERE cx.id_usuario = u.id_usuario " +
                "    AND cx.id_psicologo = ? AND cx.fecha BETWEEN ? AND ? AND cx.fecha <= CURDATE()) " +
                "GROUP BY u.id_usuario, u.nombre ORDER BY u.nombre";

            ps = con.prepareStatement(sqlPac);
            ps.setString(1, qFin); ps.setString(2, qInicio);
            ps.setInt(3, idPsicologo); ps.setString(4, qInicio); ps.setString(5, qFin);
            ps.setInt(6, idPsicologo); ps.setString(7, qInicio); ps.setString(8, qFin);
            ps.setInt(9, Integer.parseInt(empresaSelId));
            ps.setInt(10, idPsicologo); ps.setString(11, qInicio); ps.setString(12, qFin);

            rs = ps.executeQuery();
            double sumEst = 0, sumAns = 0;
            while (rs.next()) {
                int diasQ = rs.getInt("diasQuincena");
                int diasA = rs.getInt("diasAuto");
                double est = rs.getDouble("estresAvg");
                double ans = rs.getDouble("ansiedadAvg");
                int ses    = rs.getInt("sesiones");
                int pct    = diasQ > 0 ? Math.min((int)Math.round(diasA * 100.0 / diasQ), 100) : 0;

                Map<String,String> p2 = new HashMap<>();
                p2.put("id",       rs.getString("id_usuario"));
                p2.put("nombre",   rs.getString("nombre"));
                p2.put("estres",   String.format("%.1f", est / 10.0));
                p2.put("ansiedad", String.format("%.1f", ans / 10.0));
                p2.put("dinamicas", pct + "%");
                p2.put("sesiones", String.valueOf(ses));
                String idC = rs.getString("idUltimaCita");
                p2.put("idCita", idC != null ? idC : "0");
                p2.put("cEst", est > 66 ? "rojo" : est > 33 ? "amarillo" : "verde");
                p2.put("cAns", ans > 66 ? "rojo" : ans > 33 ? "amarillo" : "verde");
                p2.put("cDin", pct >= 70 ? "verde" : pct >= 40 ? "amarillo" : "rojo");
                listaPacientes.add(p2);
                sumEst += est / 10.0;
                sumAns += ans / 10.0;
            }
            totalAtendidos = listaPacientes.size();
            if (totalAtendidos > 0) {
                estresGrupal   = sumEst / totalAtendidos;
                ansiedadGrupal = sumAns / totalAtendidos;
            }
            rs.close(); ps.close();
        }

        // ── 3. HISTORIAL ─────────────────────────────────────────
        String sqlHist =
            "SELECT rq.id_reporte, e.nombre AS empresa, DATE_FORMAT(rq.fecha,'%d/%m/%Y') AS fecha " +
            "FROM reporte_quincenal rq JOIN empresa e ON rq.id_empresa = e.id_empresa " +
            "WHERE rq.id_psicologo = ? AND rq.recomendaciones IS NOT NULL AND rq.recomendaciones != '' " +
            "ORDER BY rq.fecha DESC LIMIT 15";
        ps = con.prepareStatement(sqlHist);
        ps.setInt(1, idPsicologo);
        rs = ps.executeQuery();
        while (rs.next()) {
            Map<String,String> r2 = new HashMap<>();
            r2.put("id",      rs.getString("id_reporte"));
            r2.put("empresa", rs.getString("empresa"));
            r2.put("fecha",   rs.getString("fecha"));
            listaReportes.add(r2);
        }
        rs.close(); ps.close();

    } catch (Exception e) {
        e.printStackTrace();
        if (msgError == null) msgError = "Error de conexión: " + e.getMessage();
    } finally {
        try { if (rs  != null) rs.close();  } catch (Exception ignored) {}
        try { if (ps  != null) ps.close();  } catch (Exception ignored) {}
        try { if (con != null) con.close(); } catch (Exception ignored) {}
    }

    int enRiesgo = 0;
    for (Map<String,String> p2 : listaPacientes)
        if ("rojo".equals(p2.get("cEst")) || "rojo".equals(p2.get("cAns"))) enRiesgo++;

    String empNomFinal = (empresaSelNom != null && !empresaSelNom.isEmpty())
            ? empresaSelNom : (!listaEmpresas.isEmpty() ? listaEmpresas.get(0).get("nombre") : "");

    SimpleDateFormat sdfParse   = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat sdfMostrar = new SimpleDateFormat("d MMM", new Locale("es","MX"));
    String quincenaLegible = "";
    try {
        quincenaLegible = sdfMostrar.format(sdfParse.parse(qInicio))
                        + " – " + sdfMostrar.format(sdfParse.parse(qFin));
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Reportes - Serena</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
/* ══ RESET ══ */
*{box-sizing:border-box;margin:0;padding:0;}

body{
    margin:0;
    min-height:100vh;
    display:flex;
    justify-content:center;
    align-items:center;
    background:#e6e6e6;
    font-family:'Plus Jakarta Sans',sans-serif;
}

/* ══ MARCO ══ */
.phone-frame{
    width:380px;
    height:760px;
    background:black;
    border-radius:50px;
    padding:15px;
    box-shadow:0 30px 60px rgba(0,0,0,0.4);
    display:flex;
    justify-content:center;
    align-items:center;
    flex-shrink:0;
}

/* ══ PANTALLA ══ */
.phone{
    width:340px;
    height:680px;
    background:linear-gradient(180deg,#6aa3d6,#3f6ba9);
    border-radius:40px;
    overflow:hidden;
    color:white;
    position:relative;
    display:flex;
    flex-direction:column;
}

.notch{
    width:120px;
    height:25px;
    background:black;
    border-radius:0 0 20px 20px;
    position:absolute;
    top:0;left:50%;
    transform:translateX(-50%);
    z-index:20;
}

/* ══ CABECERA ══ */
.header{
    padding:42px 20px 16px;
    text-align:center;
    flex-shrink:0;
}
.header-title{
    font-size:20px;
    font-weight:800;
    letter-spacing:-.3px;
}
.header-sub{
    font-size:11px;
    opacity:.75;
    margin-top:2px;
}

/* ══ CONTENIDO SCROLLABLE ══ */
.content{
    flex:1;
    background:rgba(0,0,0,0.22);
    border-radius:30px 30px 0 0;
    padding:16px 16px 90px;
    overflow-y:auto;
    scrollbar-width:none;
    -ms-overflow-style:none;
}
.content::-webkit-scrollbar{display:none;}

/* ══ ETIQUETAS DE SECCIÓN ══ */
.section-title{
    font-size:12px;
    font-weight:700;
    opacity:.75;
    text-transform:uppercase;
    letter-spacing:.5px;
    margin:14px 0 8px;
}

/* ══ TOASTS ══ */
.toast{
    padding:10px 12px;
    border-radius:12px;
    font-size:12px;
    font-weight:600;
    margin-bottom:10px;
    display:flex;
    align-items:center;
    gap:8px;
}
.toast-ok  { background:rgba(39,174,96,.25);  border:1px solid rgba(39,174,96,.4); }
.toast-err { background:rgba(231,76,60,.25);  border:1px solid rgba(231,76,60,.4); }

/* ══ CHIPS DE EMPRESA ══ */
.chips{
    display:flex;
    gap:7px;
    overflow-x:auto;
    padding-bottom:2px;
    margin-bottom:12px;
    scrollbar-width:none;
}
.chips::-webkit-scrollbar{display:none;}
.chip{
    white-space:nowrap;
    padding:6px 13px;
    border-radius:20px;
    border:1.5px solid rgba(255,255,255,0.3);
    background:rgba(255,255,255,0.1);
    color:rgba(255,255,255,0.85);
    font-family:'Plus Jakarta Sans',sans-serif;
    font-size:11px;
    font-weight:600;
    cursor:pointer;
    text-decoration:none;
    transition:all .2s;
}
.chip.activo{
    background:white;
    color:#3f6ba9;
    border-color:white;
    box-shadow:0 3px 10px rgba(0,0,0,0.2);
}
.chip:hover:not(.activo){background:rgba(255,255,255,0.2);}

/* ══ SELECTOR QUINCENA ══ */
.quincena-row{
    display:flex;
    align-items:center;
    gap:8px;
    margin-bottom:14px;
}
.quincena-label{
    font-size:11px;
    font-weight:600;
    opacity:.8;
    white-space:nowrap;
}
.quincena-select{
    flex:1;
    padding:7px 10px;
    border:1.5px solid rgba(255,255,255,0.3);
    border-radius:10px;
    font-family:'Plus Jakarta Sans',sans-serif;
    font-size:11px;
    font-weight:600;
    color:white;
    background:rgba(255,255,255,0.15);
    cursor:pointer;
    outline:none;
    min-width:0;
}
.quincena-select option{color:#333;background:white;}

/* ══ TARJETA BLANCA ══ */
.card{
    background:rgba(255,255,255,0.15);
    border-radius:16px;
    margin-bottom:10px;
    overflow:hidden;
}

/* ══ CABECERA DE TABLA ══ */
.card-head{
    padding:12px 14px 8px;
    border-bottom:1px solid rgba(255,255,255,0.12);
}
.card-head-title{font-size:13px;font-weight:700;}
.card-head-sub  {font-size:11px;opacity:.7;margin-top:2px;}

/* ══ TABLA ══ */
.tabla-wrap{overflow-x:auto;}
table{width:100%;border-collapse:collapse;font-size:11px;}
thead th{
    padding:7px 8px;
    text-align:left;
    font-weight:700;
    font-size:10px;
    opacity:.65;
    text-transform:uppercase;
    letter-spacing:.3px;
    white-space:nowrap;
    background:rgba(0,0,0,0.1);
}
tbody tr{border-bottom:1px solid rgba(255,255,255,0.08);}
tbody tr:last-child{border-bottom:none;}
tbody tr:hover{background:rgba(255,255,255,0.06);}
tbody td{
    padding:9px 8px;
    color:white;
    font-weight:500;
    vertical-align:middle;
}

/* ══ AVATAR ══ */
.pac-row{display:flex;align-items:center;gap:6px;min-width:75px;}
.avatar{
    width:24px;height:24px;
    border-radius:50%;
    background:rgba(255,255,255,0.25);
    display:flex;align-items:center;justify-content:center;
    font-size:9px;font-weight:800;flex-shrink:0;
}

/* ══ BADGES ══ */
.badge{
    display:inline-flex;align-items:center;
    padding:3px 7px;
    border-radius:20px;
    font-size:10px;font-weight:700;
    white-space:nowrap;
}
.badge-verde   { background:rgba(39,174,96,.3);  color:#a8f0c6; border:1px solid rgba(39,174,96,.35); }
.badge-amarillo{ background:rgba(243,156,18,.3);  color:#ffe08a; border:1px solid rgba(243,156,18,.35); }
.badge-rojo    { background:rgba(231,76,60,.3);   color:#ffb3b3; border:1px solid rgba(231,76,60,.35); }

/* ══ BTN ACCION ══ */
.btn-acc{
    background:rgba(255,255,255,0.15);
    border:none;
    border-radius:8px;
    padding:5px 8px;
    cursor:pointer;
    font-size:12px;
    color:white;
    transition:background .2s;
}
.btn-acc:hover{background:rgba(255,255,255,0.3);}

/* ══ FOOTER RIESGO ══ */
.risk-bar{
    padding:8px 14px;
    background:rgba(231,76,60,0.25);
    border-top:1px solid rgba(231,76,60,0.3);
    font-size:11px;
    font-weight:700;
    color:#ffb3b3;
    display:flex;
    align-items:center;
    gap:6px;
}

/* ══ BOTÓN GENERAR ══ */
.btn-generar{
    width:100%;
    padding:12px;
    background:white;
    color:#3f6ba9;
    border:none;
    border-radius:14px;
    font-family:'Plus Jakarta Sans',sans-serif;
    font-size:12px;
    font-weight:700;
    cursor:pointer;
    display:flex;
    align-items:center;
    justify-content:center;
    gap:7px;
    margin-bottom:14px;
    box-shadow:0 4px 16px rgba(0,0,0,0.2);
    transition:all .2s;
}
.btn-generar:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(0,0,0,0.25);}

/* ══ HISTORIAL ══ */
.reporte-card{
    background:rgba(255,255,255,0.12);
    border-radius:14px;
    padding:12px 14px;
    margin-bottom:8px;
    display:flex;
    align-items:center;
    gap:10px;
    cursor:pointer;
    text-decoration:none;
    color:white;
    border-left:3px solid rgba(255,255,255,0.4);
    transition:all .2s;
}
.reporte-card:hover{background:rgba(255,255,255,0.2);}
.rep-icon{
    width:36px;height:36px;
    background:rgba(255,255,255,0.2);
    border-radius:10px;
    display:flex;align-items:center;justify-content:center;
    font-size:16px;flex-shrink:0;
}
.rep-info{flex:1;}
.rep-empresa{font-size:12px;font-weight:700;}
.rep-fecha  {font-size:10px;opacity:.7;margin-top:2px;}
.rep-badge  {
    font-size:9px;font-weight:700;
    background:rgba(39,174,96,.3);
    color:#a8f0c6;
    border:1px solid rgba(39,174,96,.35);
    padding:2px 8px;border-radius:20px;
    white-space:nowrap;
}

/* ══ EMPTY STATE ══ */
.empty{
    text-align:center;
    padding:24px 16px;
    opacity:.6;
}
.empty .ei{font-size:32px;margin-bottom:6px;}
.empty p{font-size:12px;}

/* ══ MENÚ ══ */
.menu{
    position:absolute;
    bottom:0;width:100%;height:65px;
    background:rgba(0,0,0,0.6);
    display:flex;justify-content:space-around;align-items:center;
    font-size:11px;
    backdrop-filter:blur(5px);
}
.menu div{text-align:center;cursor:pointer;color:rgba(255,255,255,0.7);}
.menu .active{color:white;font-weight:bold;}

/* ══ MODALES ══ */
.modal-overlay{
    display:none;
    position:absolute;
    inset:0;
    background:rgba(0,0,0,0.6);
    z-index:200;
    justify-content:flex-end;
    align-items:flex-end;
    backdrop-filter:blur(3px);
    border-radius:40px;
    overflow:hidden;
}
.modal-overlay.activo{display:flex;}

.modal-sheet{
    background:linear-gradient(160deg,#5a96ce,#3a63a0);
    border-radius:24px 24px 0 0;
    width:100%;
    max-height:82%;
    overflow-y:auto;
    padding:16px 18px 24px;
    scrollbar-width:none;
    animation:slideUp .28s ease;
    color:white;
}
.modal-sheet::-webkit-scrollbar{display:none;}
@keyframes slideUp{from{transform:translateY(40px);opacity:0;}to{transform:translateY(0);opacity:1;}}

.modal-handle{
    width:36px;height:4px;
    background:rgba(255,255,255,0.3);
    border-radius:2px;
    margin:0 auto 14px;
}
.modal-titulo{font-size:15px;font-weight:800;margin-bottom:12px;}
.modal-label {font-size:10px;font-weight:700;opacity:.7;text-transform:uppercase;letter-spacing:.5px;margin:12px 0 6px;}

/* stats dentro modal */
.stats-grid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:12px;}
.stat-box{
    background:rgba(255,255,255,0.15);
    border-radius:12px;padding:10px 6px;text-align:center;
}
.stat-val{font-size:18px;font-weight:800;}
.stat-lbl{font-size:9px;opacity:.7;text-transform:uppercase;margin-top:2px;}

/* textarea dentro modal */
.modal-textarea{
    width:100%;
    padding:10px 12px;
    border:1.5px solid rgba(255,255,255,0.25);
    border-radius:12px;
    font-family:'Plus Jakarta Sans',sans-serif;
    font-size:12px;
    color:white;
    background:rgba(255,255,255,0.1);
    resize:none;
    outline:none;
    transition:border .2s;
}
.modal-textarea::placeholder{color:rgba(255,255,255,0.4);}
.modal-textarea:focus{border-color:rgba(255,255,255,0.5);background:rgba(255,255,255,0.15);}

/* botones modal */
.btn-m-p{
    width:100%;padding:12px;
    background:white;color:#3f6ba9;
    border:none;border-radius:12px;
    font-family:'Plus Jakarta Sans',sans-serif;
    font-size:12px;font-weight:700;
    cursor:pointer;margin-top:10px;
    display:flex;align-items:center;justify-content:center;gap:7px;
    transition:all .2s;
}
.btn-m-p:hover{opacity:.9;}
.btn-m-s{
    width:100%;padding:10px;
    background:transparent;
    color:rgba(255,255,255,0.7);
    border:1.5px solid rgba(255,255,255,0.25);
    border-radius:12px;
    font-family:'Plus Jakarta Sans',sans-serif;
    font-size:12px;font-weight:600;
    cursor:pointer;margin-top:8px;
    transition:all .2s;
}
.btn-m-s:hover{border-color:rgba(255,255,255,0.5);color:white;}

/* obs header en modal */
.obs-header{display:flex;align-items:center;gap:10px;margin-bottom:12px;}
.obs-av{
    width:42px;height:42px;border-radius:50%;
    background:rgba(255,255,255,0.25);
    display:flex;align-items:center;justify-content:center;
    font-size:15px;font-weight:800;flex-shrink:0;
}
.obs-nombre{font-size:14px;font-weight:700;}
.obs-sub   {font-size:11px;opacity:.65;margin-top:1px;}
</style>
</head>
<body>

<div class="phone-frame">
<div class="phone">
<div class="notch"></div>

<!-- CABECERA -->
<div class="header">
    <div class="header-title">📋 Reportes</div>
    <div class="header-sub">Gestión y seguimiento de pacientes</div>
</div>

<!-- CONTENIDO -->
<div class="content">

    <!-- TOASTS -->
    <% if (msgExito != null) { %>
    <div class="toast toast-ok">✅ <%= msgExito %></div>
    <% } %>
    <% if (msgError != null) { %>
    <div class="toast toast-err">❌ <%= msgError %></div>
    <% } %>

    <!-- FILTRO EMPRESAS -->
    <div class="section-title">Empresa</div>
    <div class="chips">
        <% if (listaEmpresas.isEmpty()) { %>
        <div style="font-size:11px;opacity:.7;">Sin citas realizadas aún</div>
        <% } else {
            for (Map<String,String> emp : listaEmpresas) {
                boolean activo = emp.get("id").equals(empresaSelId);
                String encNom  = java.net.URLEncoder.encode(emp.get("nombre"), "UTF-8");
        %>
        <a href="reportes.jsp?idEmpresa=<%= emp.get("id") %>&nomEmpresa=<%= encNom %>&inicio=<%= qInicio %>&fin=<%= qFin %>"
           class="chip <%= activo ? "activo" : "" %>">
            <%= emp.get("nombre") %>
        </a>
        <% } } %>
    </div>

    <!-- SELECTOR QUINCENA -->
    <form method="get" action="reportes.jsp" id="formQ">
        <input type="hidden" name="idEmpresa"  value="<%= empresaSelId  != null ? empresaSelId  : "" %>">
        <input type="hidden" name="nomEmpresa" value="<%= empNomFinal   != null ? empNomFinal   : "" %>">
        <input type="hidden" name="inicio" id="hInicio" value="<%= qInicio %>">
        <input type="hidden" name="fin"    id="hFin"    value="<%= qFin %>">
        <div class="quincena-row">
            <span class="quincena-label">🗓 Periodo:</span>
            <select class="quincena-select" onchange="cambiaPeriodo(this)">
                <%
                  Calendar calGen = Calendar.getInstance();
                  SimpleDateFormat sdfOpt = new SimpleDateFormat("yyyy-MM-dd");
                  SimpleDateFormat sdfLbl = new SimpleDateFormat("MMM yyyy", new Locale("es","MX"));
                  for (int i = 0; i < 6; i++) {
                      int mes2  = calGen.get(Calendar.MONTH);
                      int anio2 = calGen.get(Calendar.YEAR);
                      Calendar finMes = (Calendar) calGen.clone();
                      finMes.set(anio2, mes2, 1);
                      finMes.add(Calendar.MONTH, 1);
                      finMes.add(Calendar.DAY_OF_MONTH, -1);
                      int ultimoDia = finMes.get(Calendar.DAY_OF_MONTH);

                      String q2i = String.format("%04d-%02d-16", anio2, mes2+1);
                      String q2f = String.format("%04d-%02d-%02d", anio2, mes2+1, ultimoDia);
                      String q1i = String.format("%04d-%02d-01", anio2, mes2+1);
                      String q1f = String.format("%04d-%02d-15", anio2, mes2+1);
                      String lbl = sdfLbl.format(calGen.getTime());

                      java.util.Date hoyD = new java.util.Date();
                      if (sdfOpt.parse(q2i).compareTo(hoyD) <= 0) {
                          boolean sel2 = q2i.equals(qInicio);
                %>
                <option value="<%= q2i %>|<%= q2f %>" <%= sel2 ? "selected" : "" %>>16-<%= ultimoDia %> <%= lbl %></option>
                <%    }
                          boolean sel1 = q1i.equals(qInicio);
                %>
                <option value="<%= q1i %>|<%= q1f %>" <%= sel1 ? "selected" : "" %>>01-15 <%= lbl %></option>
                <%    calGen.add(Calendar.MONTH, -1);
                  }
                %>
            </select>
        </div>
    </form>

    <!-- TABLA PACIENTES -->
    <div class="section-title">Pacientes atendidos</div>
    <div class="card">
        <% if (empresaSelId == null || empresaSelId.isEmpty()) { %>
        <div class="empty">
            <div class="ei">🏢</div>
            <p>Selecciona una empresa para ver los datos</p>
        </div>
        <% } else if (listaPacientes.isEmpty()) { %>
        <div class="card-head">
            <div class="card-head-title"><%= empNomFinal %></div>
            <div class="card-head-sub">📅 <%= quincenaLegible %></div>
        </div>
        <div class="empty">
            <div class="ei">📭</div>
            <p>Sin citas realizadas en este periodo</p>
        </div>
        <% } else { %>
        <div class="card-head">
            <div class="card-head-title"><%= empNomFinal %></div>
            <div class="card-head-sub">📅 <%= quincenaLegible %> &nbsp;·&nbsp; <%= totalAtendidos %> pacientes</div>
        </div>
        <div class="tabla-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Paciente</th>
                        <th>Est.</th>
                        <th>Ans.</th>
                        <th>Din.</th>
                        <th>Ses.</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Map<String,String> p2 : listaPacientes) {
                        String ini = "";
                        for (String parte : p2.get("nombre").split(" "))
                            if (!parte.isEmpty() && ini.length() < 2) ini += parte.charAt(0);
                        ini = ini.toUpperCase();
                        String nomEsc = p2.get("nombre").replace("'", "\\'");
                        String empEsc = empNomFinal.replace("'", "\\'");
                    %>
                    <tr>
                        <td>
                            <div class="pac-row">
                                <div class="avatar"><%= ini %></div>
                                <span style="font-size:10px;font-weight:600;line-height:1.2;"><%= p2.get("nombre") %></span>
                            </div>
                        </td>
                        <td><span class="badge badge-<%= p2.get("cEst") %>"><%= p2.get("estres") %></span></td>
                        <td><span class="badge badge-<%= p2.get("cAns") %>"><%= p2.get("ansiedad") %></span></td>
                        <td><span class="badge badge-<%= p2.get("cDin") %>"><%= p2.get("dinamicas") %></span></td>
                        <td style="text-align:center;font-weight:700;font-size:12px;"><%= p2.get("sesiones") %></td>
                        <td>
                            <button class="btn-acc"
                                onclick="abrirObs('<%= p2.get("id") %>','<%= nomEsc %>','<%= p2.get("idCita") %>','<%= empEsc %>')">
                                ···
                            </button>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% if (enRiesgo > 0) { %>
        <div class="risk-bar">⚠️ <strong><%= enRiesgo %> paciente<%= enRiesgo>1?"s":"" %> en riesgo crítico</strong></div>
        <% } %>
        <% } %>
    </div>

    <!-- BTN GENERAR -->
    <% if (!listaPacientes.isEmpty()) { %>
    <button class="btn-generar" onclick="abrirModalResumen()">
        📄 Generar Reporte General
    </button>
    <% } %>

    <!-- HISTORIAL -->
    <div class="section-title">Historial de reportes</div>
    <% if (listaReportes.isEmpty()) { %>
    <div class="empty">
        <div class="ei">📂</div>
        <p>Aún no hay reportes generados</p>
    </div>
    <% } else { for (Map<String,String> r2 : listaReportes) { %>
    <a class="reporte-card"
       href="${pageContext.request.contextPath}/ReporteServlet?accion=verPDF&id=<%= r2.get("id") %>"
       target="_blank">
        <div class="rep-icon">📄</div>
        <div class="rep-info">
            <div class="rep-empresa"><%= r2.get("empresa") %></div>
            <div class="rep-fecha">📅 <%= r2.get("fecha") %></div>
        </div>
        <div class="rep-badge">✓ PDF</div>
    </a>
    <% } } %>

</div><!-- /content -->

<!-- MENÚ -->
<div class="menu">
    <div onclick="location.href='homePsicologo.jsp'">🏠<br>Home</div>
    <div onclick="location.href='chatPsicologo.jsp'">💬<br>Chat</div>
    <div class="active">📋<br>Reportes</div>
    <div onclick="location.href='perfilPsicologo.jsp'">👤<br>Perfil</div>
</div>

<!-- ═══ MODAL OBSERVACIONES ═══ -->
<div class="modal-overlay" id="modalObs">
    <div class="modal-sheet">
        <div class="modal-handle"></div>
        <div class="obs-header">
            <div class="obs-av" id="obsAv">?</div>
            <div>
                <div class="obs-nombre" id="obsNom">Paciente</div>
                <div class="obs-sub"    id="obsEmp">Empresa</div>
            </div>
        </div>
        <div class="modal-label">Observaciones clínicas</div>
        <textarea class="modal-textarea" id="obsTxt" rows="5"
            placeholder="Escribe tus notas sobre progreso, actitud, áreas de mejora..."></textarea>

        <form id="formObs" method="POST" action="${pageContext.request.contextPath}/ReporteServlet">
            <input type="hidden" name="accion"      value="guardarObservacion">
            <input type="hidden" name="idCita"      id="hidCita">
            <input type="hidden" name="idUsuario"   id="hidUser">
            <input type="hidden" name="observacion" id="hidObs">
        </form>

        <button class="btn-m-p" onclick="guardarObs()">💾 Guardar observación</button>
        <button class="btn-m-s" onclick="cerrar('modalObs')">Cancelar</button>
    </div>
</div>

<!-- ═══ MODAL RESUMEN / PDF ═══ -->
<div class="modal-overlay" id="modalResumen">
    <div class="modal-sheet">
        <div class="modal-handle"></div>
        <div class="modal-titulo">📊 Cierre: <%= empNomFinal %></div>

        <div class="modal-label">Resumen grupal</div>
        <div class="stats-grid">
            <div class="stat-box">
                <div class="stat-val"><%= String.format("%.1f", estresGrupal) %></div>
                <div class="stat-lbl">Estrés prom.</div>
            </div>
            <div class="stat-box">
                <div class="stat-val"><%= String.format("%.1f", ansiedadGrupal) %></div>
                <div class="stat-lbl">Ansiedad prom.</div>
            </div>
            <div class="stat-box">
                <div class="stat-val"><%= totalAtendidos %></div>
                <div class="stat-lbl">Pacientes</div>
            </div>
        </div>

        <div class="modal-label">📝 Conclusiones y recomendaciones</div>
        <textarea class="modal-textarea" id="txtRec" rows="4"
            placeholder="Escribe tus recomendaciones para la empresa..."></textarea>

        <form id="formPDF" method="POST" action="${pageContext.request.contextPath}/ReporteServlet" target="_blank">
            <input type="hidden" name="accion"           value="generarPDF">
            <input type="hidden" name="idEmpresa"        value="<%= empresaSelId != null ? empresaSelId : "" %>">
            <input type="hidden" name="nombreEmpresa"    value="<%= empNomFinal %>">
            <input type="hidden" name="quincenaInicio"   value="<%= qInicio %>">
            <input type="hidden" name="quincenaFin"      value="<%= qFin %>">
            <input type="hidden" name="estresPromedio"   value="<%= String.format("%.1f", estresGrupal) %>">
            <input type="hidden" name="ansiedadPromedio" value="<%= String.format("%.1f", ansiedadGrupal) %>">
            <input type="hidden" name="totalPacientes"   value="<%= totalAtendidos %>">
            <input type="hidden" name="recomendaciones"  id="hidRec">
        </form>

        <button class="btn-m-p" onclick="confirmarPDF()">📥 Confirmar y generar PDF</button>
        <button class="btn-m-s" onclick="cerrar('modalResumen')">Cancelar</button>
    </div>
</div>

</div><!-- /phone -->
</div><!-- /phone-frame -->

<script>
function cambiaPeriodo(sel) {
    const [ini, fin] = sel.value.split('|');
    document.getElementById('hInicio').value = ini;
    document.getElementById('hFin').value    = fin;
    document.getElementById('formQ').submit();
}

function abrirObs(idUsuario, nombre, idCita, empresa) {
    const ini = nombre.split(' ').map(n => n[0] || '').join('').substring(0,2).toUpperCase();
    document.getElementById('obsAv').textContent  = ini;
    document.getElementById('obsNom').textContent = nombre;
    document.getElementById('obsEmp').textContent = empresa;
    document.getElementById('hidCita').value = idCita;
    document.getElementById('hidUser').value = idUsuario;
    document.getElementById('obsTxt').value  = '';
    abrir('modalObs');
}

function guardarObs() {
    const txt = document.getElementById('obsTxt').value.trim();
    if (!txt) { alert('Por favor escribe una observación.'); return; }
    document.getElementById('hidObs').value = txt;
    document.getElementById('formObs').submit();
}

function abrirModalResumen() { abrir('modalResumen'); }

function confirmarPDF() {
    const rec = document.getElementById('txtRec').value.trim();
    if (!rec) { alert('Por favor escribe tus conclusiones.'); return; }
    document.getElementById('hidRec').value = rec;
    document.getElementById('formPDF').submit();
    cerrar('modalResumen');
}

function abrir(id)  { document.getElementById(id).classList.add('activo'); }
function cerrar(id) { document.getElementById(id).classList.remove('activo'); }

document.querySelectorAll('.modal-overlay').forEach(o => {
    o.addEventListener('click', e => { if (e.target === o) cerrar(o.id); });
});
</script>

</body>
</html>

