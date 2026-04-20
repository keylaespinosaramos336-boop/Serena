package com.serena;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/guardarCodigoServlet")
public class guardarCodigoServlet extends HttpServlet {
    
    // 1. Definimos las mismas constantes inteligentes
    private final String URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8"
    );

    private final String USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        // Recuperamos el ID de la empresa que guardamos en el Login
        Integer idEmpresa = (session != null) ? (Integer) session.getAttribute("idEmpresa") : null;
        String nuevoCodigo = request.getParameter("codigo");

        if (idEmpresa != null && nuevoCodigo != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {
                    // Actualizamos la columna codigo_empresa para esta empresa específica
                    String sql = "UPDATE empresa SET codigo_empresa = ? WHERE id_empresa = ?";
                    PreparedStatement pst = con.prepareStatement(sql);
                    pst.setString(1, nuevoCodigo);
                    pst.setInt(2, idEmpresa);
                    
                    int filas = pst.executeUpdate();
                    if (filas > 0) {
                        response.setStatus(HttpServletResponse.SC_OK);
                    } else {
                        response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        }
    }
}
