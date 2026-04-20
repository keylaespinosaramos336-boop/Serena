package com.serena;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;


@WebServlet(name = "registroTrabajadorServlet", urlPatterns = {"/registroTrabajadorServlet"})
public class registroTrabajadorServlet extends HttpServlet {

    // Configuración de conexión
    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8"
    );

    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Recoger datos del HTML
        String nombre = request.getParameter("nombre");
        String correo = request.getParameter("correo");
        String pass = request.getParameter("password");
        String pass2 = request.getParameter("confirmar");
        String codigoEmpresa = request.getParameter("codigo_empresa");

        // Validaciones de campos vacíos
        if (nombre == null || correo == null || pass == null || codigoEmpresa == null || 
            nombre.isEmpty() || correo.isEmpty() || pass.isEmpty() || codigoEmpresa.isEmpty()) {
            response.sendRedirect("pages/registroTrabajador.html?error=campos_vacios");
            return;
        }

        // Validación de contraseñas iguales
        if (!pass.equals(pass2)) {
            response.sendRedirect("pages/registroTrabajador.html?error=contrasena_no_coincide");
            return;
        }

        try {
            
            System.out.println("URL BD: " + URL);
            System.out.println("USER BD: " + USER);
            System.out.println("PASS BD: " + PASS);
            System.out.println("Intentando conectar...");

            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {
                System.out.println("✅ Conexión exitosa");

                // A. Buscar ID de la empresa
                int idEmpresa = -1;
                String sqlEmpresa = "SELECT id_empresa FROM empresa WHERE codigo_empresa = ?";
                try (PreparedStatement ps = con.prepareStatement(sqlEmpresa)) {
                    ps.setString(1, codigoEmpresa);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        idEmpresa = rs.getInt("id_empresa");
                    } else {
                        // Si la empresa no existe, regresamos al registro
                        response.sendRedirect("pages/registroTrabajador.html?error=empresa_no_existente");
                        return;
                    }
                }

                // B. Insertar en tabla Usuario
                String sqlUser = "INSERT INTO usuario (nombre, correo, password, tipo_usuario, id_Empresa, fecha_registro) VALUES (?, ?, ?, ?, ?, NOW())";
                int idUsuarioGenerado = -1;
                try (PreparedStatement ps = con.prepareStatement(sqlUser, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, nombre);
                    ps.setString(2, correo);
                    ps.setString(3, pass);
                    ps.setString(4, "empleado"); 
                    ps.setInt(5, idEmpresa);
                    ps.executeUpdate();
                    
                    ResultSet rsKeys = ps.getGeneratedKeys();
                    if (rsKeys.next()) {
                        idUsuarioGenerado = rsKeys.getInt(1);
                    }
                }

                // C. Insertar en tabla empleado
                if (idUsuarioGenerado != -1) {
                    String sqlEmpleado = "INSERT INTO empleado (id_usuario, activo) VALUES (?, 1)";
                    try (PreparedStatement ps = con.prepareStatement(sqlEmpleado)) {
                        ps.setInt(1, idUsuarioGenerado);
                        ps.executeUpdate();
                    }
                }

                // --- CORRECCIÓN AQUÍ ---
                // Redirigir al Login para que el usuario inicie sesión
                response.sendRedirect("pages/login.html?registro=exito");

            }
        } catch (Exception e) {
            e.printStackTrace();
            // Si algo falla, regresamos al registro con aviso de error
            response.sendRedirect("pages/registroTrabajador.html?error=fallo_servidor");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("pages/registroTrabajador.html");
    }
}