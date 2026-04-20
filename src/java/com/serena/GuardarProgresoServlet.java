package com.serena;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "GuardarProgresoServlet", urlPatterns = {"/GuardarProgresoServlet"})
public class GuardarProgresoServlet extends HttpServlet {
    
    // Definimos las constantes inteligentes arriba para no repetir código
    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8"
    );

    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // 1. FORZAR CODIFICACIÓN UTF-8 (Debe ir antes de obtener parámetros)
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        PrintWriter out = response.getWriter();
        
        // 2. Obtener sesión e ID de usuario
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("idUsuario") == null) {
            out.print("error: sesión no iniciada");
            return;
        }
        
        int idUsuario = (int) session.getAttribute("idUsuario");
        
        // 3. Obtener parámetros (Ahora vendrán correctamente con acentos)
        String titulo = request.getParameter("titulo");
        String imagen = request.getParameter("imagen");
        String tiempo = request.getParameter("tiempo");

        Connection con = null;
        PreparedStatement ps = null;

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // 4. URL DE CONEXIÓN CON UTF-8
            // Cambia esto en tu DriverManager.getConnection:
            con = DriverManager.getConnection(URL, USER, PASS);

            // 5. SQL OPTIMIZADO (Usando VALUES() para no repetir parámetros)
            String sql = "INSERT INTO progreso_reproduccion (id_usuario, titulo_contenido, imagen_url, tiempo_reproducido, fecha) "
                       + "VALUES (?, ?, ?, ?, CURDATE()) "
                       + "ON DUPLICATE KEY UPDATE tiempo_reproducido = VALUES(tiempo_reproducido), imagen_url = VALUES(imagen_url)";

            ps = con.prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ps.setString(2, titulo);
            ps.setString(3, imagen);
            ps.setString(4, tiempo);

            int filas = ps.executeUpdate();
            
            if (filas > 0) {
                out.print("success");
            } else {
                out.print("no_changes");
            }

        } catch (Exception e) {
            e.printStackTrace();
            out.print("error: " + e.getMessage());
        } finally {
            try { if (ps != null) ps.close(); } catch (Exception e) {}
            try { if (con != null) con.close(); } catch (Exception e) {}
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("homeTrabajador.jsp");
    }
}