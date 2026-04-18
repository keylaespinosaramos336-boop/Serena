package com.serena;

import java.io.IOException;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet(name = "loginServlet", urlPatterns = {"/loginServlet"})
public class loginServlet extends HttpServlet {

    // Configuración de conexión (Verificada con tu script SQL)
    private final String URL = "jdbc:mysql://localhost:3306/bd_serena?useSSL=false&serverTimezone=UTC";
    private final String USER = "root";
    private final String PASS = "Keylabd2603";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String correo = request.getParameter("correo");
        String password = request.getParameter("password");
        String codigoIngresado = request.getParameter("codigo_empresa");

        // 1. Validación de campos básicos
        if (correo == null || correo.isEmpty() || password == null || password.isEmpty()) {
            response.sendRedirect("pages/login.html?error=campos_vacios");
            return;
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                // --- CASO A: SI INGRESÓ UN CÓDIGO (Es trabajador de una empresa) ---
                if (codigoIngresado != null && !codigoIngresado.trim().isEmpty()) {
                    // Nota: Se usa 'usuario' y 'empresa' en minúsculas para coincidir con el Workbench
                    String sqlEmpleado = "SELECT u.nombre, u.tipo_usuario, u.id_usuario, e.id_empresa " +
                                         "FROM usuario u JOIN empresa e ON u.id_empresa = e.id_empresa " +
                                         "WHERE u.correo=? AND u.password=? AND e.codigo_empresa=?";
                    
                    try (PreparedStatement pst = con.prepareStatement(sqlEmpleado)) {
                        pst.setString(1, correo);
                        pst.setString(2, password);
                        pst.setString(3, codigoIngresado);
                        
                        try (ResultSet rs = pst.executeQuery()) {
                            if (rs.next()) {
                                HttpSession session = request.getSession();
                                session.setAttribute("idUsuario", rs.getInt("id_usuario"));
                                session.setAttribute("nombreUsuario", rs.getString("nombre"));
                                session.setAttribute("tipoUsuario", rs.getString("tipo_usuario"));
                                session.setAttribute("idEmpresa", rs.getInt("id_empresa"));
                                
                                // Redirigir al JSP para procesar el nombre dinámicamente
                                response.sendRedirect("pages/homeTrabajador.jsp");
                                return;
                            } else {
                                response.sendRedirect("pages/login.html?error=codigo_incorrecto");
                                return;
                            }
                        }
                    }
                }

                // --- CASO B: NO HAY CÓDIGO (Psicólogo, General o Empresa Directa) ---
                
                // --- CASO B.1: Intentar en la tabla 'usuario' (Psicólogos o Usuarios Generales) ---
                String sqlGen = "SELECT id_usuario, nombre, tipo_usuario FROM usuario WHERE correo=? AND password=?";
                try (PreparedStatement pstG = con.prepareStatement(sqlGen)) {
                    pstG.setString(1, correo);
                    pstG.setString(2, password);

                    try (ResultSet rsG = pstG.executeQuery()) {
                        if (rsG.next()) {
                            HttpSession session = request.getSession();
                            int idUsuario = rsG.getInt("id_usuario");
                            String nombre = rsG.getString("nombre");
                            String tipo = rsG.getString("tipo_usuario");

                            session.setAttribute("idUsuario", idUsuario);
                            session.setAttribute("nombreUsuario", nombre);
                            session.setAttribute("tipoUsuario", tipo);

                            // --- LÓGICA EXTRA PARA PSICÓLOGOS ---
                            if ("psicologo".equalsIgnoreCase(tipo)) {
                                // Buscamos su ID específico en la tabla psicologo
                                String sqlPsi = "SELECT id_psicologo FROM psicologo WHERE id_usuario = ?";
                                try (PreparedStatement pstP = con.prepareStatement(sqlPsi)) {
                                    pstP.setInt(1, idUsuario);
                                    try (ResultSet rsP = pstP.executeQuery()) {
                                        if (rsP.next()) {
                                            // GUARDAMOS EL ID_PSICOLOGO EN SESIÓN
                                            session.setAttribute("idPsicologo", rsP.getInt("id_psicologo"));
                                        }
                                    }
                                }
                                response.sendRedirect("pages/homePsicologo.jsp"); 
                            } 
                            // --- FIN LÓGICA EXTRA ---

                            else if("empleado".equalsIgnoreCase(tipo)){
                                response.sendRedirect("pages/homeTrabajador.jsp");
                            } else {
                                response.sendRedirect("pages/homeGeneral.jsp");
                            }
                            return;
                        }
                    }
                }

                // B.2 Intentar en la tabla 'empresa' (Si es la cuenta principal de la empresa)
                String sqlEmp = "SELECT id_empresa, nombre FROM empresa WHERE correo=? AND password=?";
                try (PreparedStatement pstE = con.prepareStatement(sqlEmp)) {
                    pstE.setString(1, correo);
                    pstE.setString(2, password);
                    
                    try (ResultSet rsE = pstE.executeQuery()) {
                        if (rsE.next()) {
                            HttpSession session = request.getSession();
                            session.setAttribute("idEmpresa", rsE.getInt("id_empresa"));
                            session.setAttribute("nombreEmpresa", rsE.getString("nombre"));
                            session.setAttribute("tipoUsuario", "empresa");
                            
                            response.sendRedirect("pages/perfilEmpresa.html"); // Cambiado a .jsp por consistencia
                            return;
                        }
                    }
                }

                // Si no se encontró en ninguna tabla
                response.sendRedirect("pages/login.html?error=incorrecto");

            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("pages/login.html?error=error_servidor");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Si intentan entrar por URL al servlet, mandarlos al login
        response.sendRedirect("pages/login.html");
    }
}