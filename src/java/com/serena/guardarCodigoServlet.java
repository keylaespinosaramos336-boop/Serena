package com.serena;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/guardarCodigoServlet")
public class guardarCodigoServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        // Recuperamos el ID de la empresa que guardamos en el Login
        Integer idEmpresa = (session != null) ? (Integer) session.getAttribute("idEmpresa") : null;
        String nuevoCodigo = request.getParameter("codigo");

        if (idEmpresa != null && nuevoCodigo != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/bd_serena", "root", "Keylabd2603")) {
                    // Actualizamos la columna codigo_empresa para esta empresa específica
                    String sql = "UPDATE Empresa SET codigo_empresa = ? WHERE id_empresa = ?";
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
