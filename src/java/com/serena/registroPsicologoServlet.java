package com.serena;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet(name = "registroPsicologoServlet", urlPatterns = {"/registroPsicologoServlet"})
public class registroPsicologoServlet extends HttpServlet {

    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8"
    );

    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // 1. Recuperar parámetros del formulario
        String nombre = request.getParameter("nombre");
        String correo = request.getParameter("correo");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirm_password");
        String cedula = request.getParameter("cedula");
        String especialidad = request.getParameter("especialidad");

        // 2. Validación básica de contraseñas
        if (password == null || !password.equals(confirmPassword)) {
            response.sendRedirect("pages/registroPsicologo.html?error=password_mismatch");
            return;
        }

        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(URL, USER, PASS);
            
            // Iniciamos transacción
            con.setAutoCommit(false); 

            // 3. Insertar en tabla 'Usuario' (Nota la U mayúscula como en tu script)
            String sqlUsuario = "INSERT INTO usuario (nombre, correo, password, tipo_usuario, fecha_registro) VALUES (?, ?, ?, 'psicologo', NOW())";
            PreparedStatement psUser = con.prepareStatement(sqlUsuario, Statement.RETURN_GENERATED_KEYS);
            psUser.setString(1, nombre);
            psUser.setString(2, correo);
            psUser.setString(3, password);
            psUser.executeUpdate();

            // Obtener el ID generado para el usuario
            ResultSet rs = psUser.getGeneratedKeys();
            int idUsuario = 0;
            if (rs.next()) {
                idUsuario = rs.getInt(1);
            }

            // 4. Insertar en tabla 'psicologo' (Usando la columna 'cedula' que actualizaste)
            String sqlPsicologo = "INSERT INTO psicologo (id_usuario, cedula, especialidad) VALUES (?, ?, ?)";
            PreparedStatement psPsi = con.prepareStatement(sqlPsicologo);
            psPsi.setInt(1, idUsuario);
            psPsi.setString(2, cedula);
            psPsi.setString(3, especialidad);
            psPsi.executeUpdate();

            // 5. Si todo salió bien, confirmamos la transacción
            con.commit(); 
            response.sendRedirect("pages/login.html?registro=exito");

        } catch (Exception e) {
            // Si algo falla, revertimos los cambios para no dejar datos incompletos
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            response.sendRedirect("pages/registroPsicologo.html?error=sql");
        } finally {
            if (con != null) {
                try { con.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }
}