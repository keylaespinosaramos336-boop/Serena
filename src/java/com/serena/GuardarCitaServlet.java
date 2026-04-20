package com.serena;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "GuardarCitaServlet", urlPatterns = {"/GuardarCitaServlet"})
public class GuardarCitaServlet extends HttpServlet {
    
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
        
        // 1. Configurar codificación para evitar problemas con acentos o emojis
        request.setCharacterEncoding("UTF-8");
        
        // 2. Recuperar parámetros del formulario (los names de tus inputs)
        String fecha = request.getParameter("fecha_cita");
        String hora = request.getParameter("hora_cita");
        String modalidad = request.getParameter("modalidad"); // 'virtual' o 'presencial'
        String idPacienteStr = request.getParameter("id_usuario_paciente");
        
        // 3. Obtener el ID del psicólogo desde la sesión
        HttpSession session = request.getSession();
        Integer idPsicologo = (Integer) session.getAttribute("idPsicologo");

        // Validación básica
        if (idPsicologo == null || idPacienteStr == null || fecha == null) {
            response.sendRedirect("pages/homePsicologo.jsp?error=datos_incompletos");
            return;
        }

        Connection conn = null;
        PreparedStatement ps = null;

        try {
            // 4. Conexión a la base de datos (ajusta tus credenciales)
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(URL, USER, PASS);

            // 5. Query SQL basado en tu tabla 'cita'
            // Los ENUM 'virtual'/'presencial' y 'pendiente' deben ir en minúsculas como en tu BD
            String sql = "INSERT INTO cita (fecha, hora, modalidad, estado, id_usuario, id_psicologo) VALUES (?, ?, ?, 'pendiente', ?, ?)";
            
            ps = conn.prepareStatement(sql);
            ps.setString(1, fecha);
            ps.setString(2, hora);
            ps.setString(3, modalidad.toLowerCase()); // Aseguramos minúsculas para el ENUM
            ps.setInt(4, Integer.parseInt(idPacienteStr)); // ID del paciente (tabla usuario)
            ps.setInt(5, idPsicologo); // ID del psicólogo logueado

            int filasInsertadas = ps.executeUpdate();

            if (filasInsertadas > 0) {
                // Éxito: volvemos al home
                response.sendRedirect("pages/homePsicologo.jsp?success=cita_guardada");
            } else {
                response.sendRedirect("pages/homePsicologo.jsp?error=no_insertado");
            }

        } catch (Exception e) {
            e.printStackTrace();
            // Si hay un error (ej. el ID de usuario no existe), mandamos el error por URL
            response.sendRedirect("pages/homePsicologo.jsp?error=db&detalle=" + e.getMessage());
        } finally {
            // 6. Cerrar recursos
            try { if (ps != null) ps.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }

    @Override
    public String getServletInfo() {
        return "Servlet que guarda citas en la BD de Serena";
    }
}
