package com.serena;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * Servlet para el chat PSICÓLOGO ↔ PACIENTE.
 *
 * Acciones soportadas:
 *   GET  accion=getMensajes  → devuelve JSON con mensajes del chat
 *   POST accion=enviar       → inserta un mensaje del psicólogo
 *   POST accion=marcarLeido  → marca como leídos los mensajes del paciente en el chat
 */
@WebServlet(name = "ChatPsicologoServlet", urlPatterns = {"/ChatPsicologoServlet"})
public class ChatPsicologoServlet extends HttpServlet {

    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway" +
        "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" +
        "&useUnicode=true&characterEncoding=UTF-8"
    );
    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    // ══════════════════════════════════════════════════════════
    //  GET  →  obtener mensajes
    // ══════════════════════════════════════════════════════════
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        // Validar sesión
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("idPsicologo") == null) {
            out.print("[]");
            return;
        }
        int idPsicologo = (Integer) session.getAttribute("idPsicologo");

        String accion      = request.getParameter("accion");
        String idChatStr   = request.getParameter("idChat");
        String desdeStr    = request.getParameter("desde");

        if (!"getMensajes".equals(accion) || idChatStr == null) {
            out.print("[]");
            return;
        }

        try {
            int idChat = Integer.parseInt(idChatStr);
            int desde  = (desdeStr != null && !desdeStr.isEmpty()) ? Integer.parseInt(desdeStr) : 0;

            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                // Verificar que el chat pertenece al psicólogo (seguridad)
                String sqlChk = "SELECT 1 FROM chat_psicologo WHERE id_chat = ? AND id_psicologo = ?";
                try (PreparedStatement ps = con.prepareStatement(sqlChk)) {
                    ps.setInt(1, idChat);
                    ps.setInt(2, idPsicologo);
                    ResultSet rs = ps.executeQuery();
                    if (!rs.next()) {
                        out.print("[]");
                        return;
                    }
                }

                // Traer mensajes
                String sql =
                    "SELECT id_mensaje, remitente, mensaje, " +
                    "DATE_FORMAT(fecha, '%H:%i') AS hora " +
                    "FROM mensaje_psicologo " +
                    "WHERE id_chat = ? AND id_mensaje > ? " +
                    "ORDER BY fecha ASC";

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, idChat);
                    ps.setInt(2, desde);
                    ResultSet rs = ps.executeQuery();

                    StringBuilder sb = new StringBuilder("[");
                    boolean first = true;
                    while (rs.next()) {
                        if (!first) sb.append(",");
                        first = false;
                        sb.append("{");
                        sb.append("\"id\":"       ).append(rs.getInt("id_mensaje")).append(",");
                        sb.append("\"remitente\":\"").append(escJson(rs.getString("remitente"))).append("\",");
                        sb.append("\"mensaje\":\""  ).append(escJson(rs.getString("mensaje"))).append("\",");
                        sb.append("\"hora\":\""     ).append(escJson(rs.getString("hora"))).append("\"");
                        sb.append("}");
                    }
                    sb.append("]");
                    out.print(sb.toString());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            out.print("[]");
        }
    }

    // ══════════════════════════════════════════════════════════
    //  POST  →  enviar mensaje / marcar leído
    // ══════════════════════════════════════════════════════════
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();

        // Validar sesión
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("idPsicologo") == null) {
            out.print("Error: Sesión expirada");
            return;
        }
        int idPsicologo = (Integer) session.getAttribute("idPsicologo");

        String accion    = request.getParameter("accion");
        String idChatStr = request.getParameter("idChat");

        if (idChatStr == null) { out.print("Error: Datos incompletos"); return; }

        try {
            int idChat = Integer.parseInt(idChatStr);
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                // Verificar que el chat pertenece al psicólogo (seguridad)
                String sqlChk = "SELECT 1 FROM chat_psicologo WHERE id_chat = ? AND id_psicologo = ?";
                try (PreparedStatement ps = con.prepareStatement(sqlChk)) {
                    ps.setInt(1, idChat);
                    ps.setInt(2, idPsicologo);
                    ResultSet rs = ps.executeQuery();
                    if (!rs.next()) { out.print("Error: Chat no autorizado"); return; }
                }

                // ── ENVIAR MENSAJE ─────────────────────────────
                if ("enviar".equals(accion)) {
                    String mensaje = request.getParameter("mensaje");
                    if (mensaje == null || mensaje.trim().isEmpty()) {
                        out.print("Error: Mensaje vacío");
                        return;
                    }

                    String sqlIns =
                        "INSERT INTO mensaje_psicologo (remitente, mensaje, fecha, id_chat, leido) " +
                        "VALUES ('psicologo', ?, NOW(), ?, 0)";
                    try (PreparedStatement ps = con.prepareStatement(sqlIns)) {
                        ps.setString(1, mensaje.trim());
                        ps.setInt(2, idChat);
                        int filas = ps.executeUpdate();
                        out.print(filas > 0 ? "OK" : "Error: No se pudo guardar");
                    }

                // ── MARCAR COMO LEÍDO ──────────────────────────
                } else if ("marcarLeido".equals(accion)) {
                    String sqlUpd =
                        "UPDATE mensaje_psicologo SET leido = 1 " +
                        "WHERE id_chat = ? AND remitente = 'usuario' AND leido = 0";
                    try (PreparedStatement ps = con.prepareStatement(sqlUpd)) {
                        ps.setInt(1, idChat);
                        ps.executeUpdate();
                        out.print("OK");
                    }
                } else {
                    out.print("Error: Acción desconocida");
                }
            }
        } catch (NumberFormatException e) {
            out.print("Error: ID inválido");
        } catch (ClassNotFoundException e) {
            out.print("Error: Driver no encontrado");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("Error: " + e.getMessage());
        }
    }

    // ── Helper: escapar caracteres especiales para JSON ────────
    private String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
