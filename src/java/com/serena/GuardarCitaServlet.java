package com.serena;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "GuardarCitaServlet", urlPatterns = {"/GuardarCitaServlet"})
public class GuardarCitaServlet extends HttpServlet {
    
    private final String URL = System.getenv().getOrDefault("DB_URL", "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8");
    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String accion = request.getParameter("accion"); // 'crear', 'eliminar', 'actualizar'
        HttpSession session = request.getSession();
        Integer idPsicologo = (Integer) session.getAttribute("idPsicologo");

        try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {
            Class.forName("com.mysql.cj.jdbc.Driver");

            if ("crear".equals(accion)) {
                String sql = "INSERT INTO cita (fecha, hora, modalidad, estado, id_usuario, id_psicologo) VALUES (?, ?, ?, 'pendiente', ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, request.getParameter("fecha_cita"));
                    ps.setString(2, request.getParameter("hora_cita"));
                    ps.setString(3, request.getParameter("modalidad").toLowerCase());
                    ps.setInt(4, Integer.parseInt(request.getParameter("id_usuario_paciente")));
                    ps.setInt(5, idPsicologo);
                    ps.executeUpdate();
                }
            } 
            else if ("eliminar".equals(accion)) {
                String sql = "DELETE FROM cita WHERE id_cita = ? AND id_psicologo = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("id_cita")));
                    ps.setInt(2, idPsicologo);
                    ps.executeUpdate();
                }
            } 
            else if ("actualizar".equals(accion)) {
                String sql = "UPDATE cita SET fecha = ?, hora = ?, modalidad = ? WHERE id_cita = ? AND id_psicologo = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, request.getParameter("fecha_cita"));
                    ps.setString(2, request.getParameter("hora_cita"));
                    ps.setString(3, request.getParameter("modalidad").toLowerCase());
                    ps.setInt(4, Integer.parseInt(request.getParameter("id_cita")));
                    ps.setInt(5, idPsicologo);
                    ps.executeUpdate();
                }
            }
            response.sendRedirect("pages/homePsicologo.jsp?success=operacion_exitosa");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("pages/homePsicologo.jsp?error=db_error");
        }
    }
}