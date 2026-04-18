package com.serena;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet(name = "MensajePsicologoSerlvet", urlPatterns = {"/MensajePsicologoSerlvet"})
public class MensajePsicologoSerlvet extends HttpServlet {

    private final String DB_URL = "jdbc:mysql://localhost:3306/bd_serena";
    private final String DB_USER = "root";
    private final String DB_PASS = "Keylabd2603";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String mensaje = request.getParameter("mensaje");
        String idPsicologoStr = request.getParameter("idPsicologo");

        // 1. Validar Sesión
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("idUsuario") == null) {
            out.print("Error: Sesión expirada.");
            return;
        }

        int idUsuario;
        try {
            Object idObj = session.getAttribute("idUsuario");
            if (idObj instanceof Integer) {
                idUsuario = (Integer) idObj;
            } else {
                idUsuario = Integer.parseInt(idObj.toString());
            }
        } catch (Exception e) {
            out.print("Error: ID de usuario no válido en sesión.");
            return;
        }

        // 2. Validaciones
        if (mensaje == null || mensaje.trim().isEmpty() || idPsicologoStr == null) {
            out.print("Error: Datos incompletos");
            return;
        }

        try {
            int idPsicologoUsuario = Integer.parseInt(idPsicologoStr); // 👈 ESTE ES id_usuario
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

                int idPsicologo = -1;
                int idChat = -1;

                // 🔥 1. CONVERTIR id_usuario → id_psicologo
                String sqlGetPsico = "SELECT id_psicologo FROM psicologo WHERE id_usuario = ?";
                try (PreparedStatement psGet = con.prepareStatement(sqlGetPsico)) {
                    psGet.setInt(1, idPsicologoUsuario);
                    try (ResultSet rs = psGet.executeQuery()) {
                        if (rs.next()) {
                            idPsicologo = rs.getInt("id_psicologo");
                        } else {
                            out.print("Error: Psicólogo no encontrado");
                            return;
                        }
                    }
                }

                // 🔍 2. BUSCAR CHAT EXISTENTE
                String sqlChat = "SELECT id_chat FROM chat_psicologo WHERE id_usuario = ? AND id_psicologo = ?";
                try (PreparedStatement ps = con.prepareStatement(sqlChat)) {
                    ps.setInt(1, idUsuario);
                    ps.setInt(2, idPsicologo);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            idChat = rs.getInt("id_chat");
                        }
                    }
                }

                // ➕ 3. CREAR CHAT SI NO EXISTE
                if (idChat == -1) {
                    String insertChat = "INSERT INTO chat_psicologo (id_usuario, id_psicologo, fecha_inicio) VALUES (?, ?, NOW())";
                    try (PreparedStatement psIns = con.prepareStatement(insertChat, PreparedStatement.RETURN_GENERATED_KEYS)) {
                        psIns.setInt(1, idUsuario);
                        psIns.setInt(2, idPsicologo);
                        psIns.executeUpdate();

                        try (ResultSet rsK = psIns.getGeneratedKeys()) {
                            if (rsK.next()) {
                                idChat = rsK.getInt(1);
                            }
                        }
                    }
                }

                // 💬 4. INSERTAR MENSAJE
                if (idChat != -1) {
                    String sqlMsg = "INSERT INTO mensaje_psicologo (remitente, mensaje, fecha, id_chat, leido) VALUES (?, ?, NOW(), ?, 0)";
                    try (PreparedStatement psMsg = con.prepareStatement(sqlMsg)) {
                        psMsg.setString(1, "usuario");
                        psMsg.setString(2, mensaje);
                        psMsg.setInt(3, idChat);

                        int filas = psMsg.executeUpdate();
                        if (filas > 0) {
                            out.print("Enviado");
                        } else {
                            out.print("Error: No se pudo guardar el mensaje.");
                        }
                    }
                } else {
                    out.print("Error: No se pudo crear el chat.");
                }

            } catch (Exception e) {
                e.printStackTrace();
                out.print("Error en la base de datos: " + e.getMessage());
            }

        } catch (NumberFormatException e) {
            out.print("Error: ID de psicólogo inválido");
        } catch (ClassNotFoundException e) {
            out.print("Error: Driver no encontrado");
        }
    }
}