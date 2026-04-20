package com.serena;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet(name = "registroEmpresaServlet", urlPatterns = {"/registroEmpresaServlet"})
public class registroEmpresaServlet extends HttpServlet {
    
    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8"
    );

    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // 1. Obtener parámetros del formulario
        String nombreE = request.getParameter("nombreEmpresa");
        String responsable = request.getParameter("nombreResponsable");
        String correo = request.getParameter("correo");
        String pass = request.getParameter("password");
        String numEmpStr = request.getParameter("numEmpleados");
        int numEmp = (numEmpStr != null && !numEmpStr.isEmpty()) ? Integer.parseInt(numEmpStr) : 0;

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                // 2. SQL de inserción según tu tabla 'Empresa'
                String sql = "INSERT INTO empresa (nombre, nombre_encargado, correo, password, numero_empleados, fecha_registro) VALUES (?, ?, ?, ?, ?, CURDATE())";
                
                try (PreparedStatement pst = con.prepareStatement(sql)) {
                    pst.setString(1, nombreE);
                    pst.setString(2, responsable);
                    pst.setString(3, correo);
                    pst.setString(4, pass);
                    pst.setInt(5, numEmp);

                    int filas = pst.executeUpdate();
                    if (filas > 0) {
                        // Éxito: Mandar al login
                        response.sendRedirect("pages/login.html?registro=exito");
                    } else {
                        response.sendRedirect("pages/registroEmpresa.html?error=falla_insercion");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("pages/registroEmpresa.html?error=error_db");
        }
    }
}