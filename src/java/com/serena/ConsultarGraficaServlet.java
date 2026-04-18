package com.serena;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "ConsultarGraficaServlet", urlPatterns = {"/ConsultarGraficaServlet"})
public class ConsultarGraficaServlet extends HttpServlet {

    // Tus datos de conexión
    private final String URL = "jdbc:mysql://localhost:3306/bd_serena?useSSL=false&serverTimezone=UTC";
    private final String USER = "root";
    private final String PASS = "Keylabd2603";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer idUsuario = (Integer) session.getAttribute("idUsuario");

        // Si no hay sesión, mandarlo al login
        if (idUsuario == null) {
            response.sendRedirect("pages/login.html");
            return;
        }

        List<String> etiquetas = new ArrayList<>();
        List<Double> valores = new ArrayList<>();

        // Consulta que promedia por día y toma los últimos 7 días con registros
        String sql = "SELECT DATE_FORMAT(fecha, '%d/%m') AS dia, AVG(porcentaje) AS promedio " +
                     "FROM registroanimo WHERE id_usuario = ? " +
                     "GROUP BY DATE(fecha) " +
                     "ORDER BY fecha ASC LIMIT 7";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS);
                 PreparedStatement pst = con.prepareStatement(sql)) {
                
                pst.setInt(1, idUsuario);
                
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        etiquetas.add(rs.getString("dia"));
                        // Redondeamos el promedio a 1 decimal para que la gráfica no sea vea rara
                        valores.add(Math.round(rs.getDouble("promedio") * 10.0) / 10.0);
                    }
                }
            }
            
            // Enviamos las listas al JSP de perfil
            request.setAttribute("etiquetasGrafica", etiquetas);
            request.setAttribute("valoresGrafica", valores);
            
            // IMPORTANTE: Asegúrate de que la ruta sea correcta según tu carpeta
            request.getRequestDispatcher("pages/perfilTrabajador.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("pages/homeTrabajador.jsp?error=grafica");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Redirigir al GET si alguien intenta usar POST
        doGet(request, response);
    }
}