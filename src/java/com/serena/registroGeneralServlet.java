package com.serena;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet(name = "registroGeneralServlet", urlPatterns = {"/registroGeneralServlet"})
public class registroGeneralServlet extends HttpServlet {

    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8"
    );

    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String nombre = request.getParameter("nombre");
        String correo = request.getParameter("correo");
        String pass = request.getParameter("password");
        String pass2 = request.getParameter("confirmar");

        // Validaciones básicas
        if (nombre == null || correo == null || pass == null || !pass.equals(pass2)) {
            response.sendRedirect("pages/registroGeneral.html?error=datos_invalidos");
            return;
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {
                
                // Insertamos en Usuario. id_Empresa es NULL porque es usuario normal, no empleado.
                String sql = "INSERT INTO usuario (nombre, correo, password, tipo_usuario, fecha_registro, id_Empresa) VALUES (?, ?, ?, ?, NOW(), NULL)";
                
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, nombre);
                    ps.setString(2, correo);
                    ps.setString(3, pass);
                    ps.setString(4, "normal"); // Valor del ENUM en tu BD
                    
                    ps.executeUpdate();
                }
                
                // Si todo sale bien, al login
                response.sendRedirect("pages/login.html?registro=exito");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("pages/registroGeneral.html?error=error_db");
        }
    }
}
