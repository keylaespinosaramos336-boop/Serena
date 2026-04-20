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

@WebServlet(name = "RegistroAnimoServlet", urlPatterns = {"/RegistroAnimoServlet"})
public class RegistroAnimoServlet extends HttpServlet {
    
    // 1. Declaramos las constantes aquí arriba
    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8"
    );

    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        String valorParam = request.getParameter("valor");
        HttpSession session = request.getSession(false);
        
        // 1. Verificación de sesión
        if (session == null || session.getAttribute("idUsuario") == null || valorParam == null) {
            out.print("error_sesion");
            return;
        }

        try {
            int idUsuario = (int) session.getAttribute("idUsuario");
            int porcentaje = Integer.parseInt(valorParam);

            // 2. Conexión a la BD
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(URL, USER, PASS);

            // 3. SQL corregido según tu archivo sql.sql (tabla 'registroanimo')
            // Se inserta id_usuario y porcentaje. La fecha se pone sola si en el SQL pusiste DEFAULT CURRENT_TIMESTAMP
            // pero por seguridad usaremos NOW() de MySQL.
            String sql = "INSERT INTO registroanimo (id_usuario, porcentaje, fecha) VALUES (?, ?, NOW())";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ps.setInt(2, porcentaje);

            int filas = ps.executeUpdate();

            if (filas > 0) {
                out.print("success"); 
            } else {
                out.print("error_db");
            }

            ps.close();
            con.close();

        } catch (Exception e) {
            e.printStackTrace();
            out.print("error_exception: " + e.getMessage());
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }
}