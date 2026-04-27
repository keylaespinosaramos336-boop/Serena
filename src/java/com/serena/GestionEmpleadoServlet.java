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

@WebServlet(name = "GestionEmpleadoServlet", urlPatterns = {"/GestionEmpleadoServlet"})
public class GestionEmpleadoServlet extends HttpServlet {

    // Variables de conexión (puedes moverlas a una clase de utilidad en el futuro)
    private final String URL = System.getenv().getOrDefault("DB_URL", "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC");
    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer idEmpresa = (Integer) session.getAttribute("idEmpresa");
        
        // Verificación básica de sesión
        if (idEmpresa == null) {
            response.sendRedirect("login.html");
            return;
        }

        String accion = request.getParameter("accion");

        if ("darDeBaja".equals(accion)) {
            String idEmpleado = request.getParameter("idEmpleado");
            
            try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {
                // Eliminamos el empleado asegurándonos de que pertenezca a la empresa del usuario logueado
                String sql = "DELETE FROM empleado WHERE id_empleado = ? AND id_empresa = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, idEmpleado);
                    ps.setInt(2, idEmpresa);
                    ps.executeUpdate();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // Redirigimos de vuelta a la página de empleados para recargar la lista
        response.sendRedirect("infoEmpleados.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Por seguridad, redirigimos los GET a la vista principal si intentan entrar directo
        response.sendRedirect("infoEmpleados.jsp");
    }
}