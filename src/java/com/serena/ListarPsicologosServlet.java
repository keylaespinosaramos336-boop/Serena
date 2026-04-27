package com.serena;

import java.io.*;
import java.net.*;
import java.sql.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet(name = "ListarPsicologosServlet", urlPatterns = {"/ListarPsicologosServlet"})
public class ListarPsicologosServlet extends HttpServlet {

    // Configuración de BD (Usa variables de entorno de Railway)
    private final String DB_URL = System.getenv().getOrDefault("DB_URL", "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8");
    private final String DB_USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String DB_PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    // IA Config (Obtenida desde variables de entorno)
    private static final String API_KEY = System.getenv("GEMINI_API_KEY");
    // Usa esta URL en tu código Java:
    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        Integer idLogueado = (session != null) ? (Integer) session.getAttribute("idUsuario") : null;

        List<Psicologo> listaPsicologos = new ArrayList<>();
        List<ChatLista> misChats = new ArrayList<>();

        if (idLogueado != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
                    // 1. Cargar Psicólogos
                    String sqlPsico = "SELECT u.id_usuario, u.nombre, u.foto, p.cedula, p.especialidad, p.experiencia, p.modalidad " +
                                      "FROM usuario u INNER JOIN psicologo p ON u.id_usuario = p.id_usuario";
                    try (PreparedStatement ps1 = con.prepareStatement(sqlPsico); ResultSet rs1 = ps1.executeQuery()) {
                        while (rs1.next()) {
                            listaPsicologos.add(new Psicologo(rs1.getInt("id_usuario"), rs1.getString("nombre"), rs1.getString("especialidad"), procesarFoto(rs1.getString("foto")), rs1.getString("experiencia"), rs1.getString("cedula"), rs1.getString("modalidad")));
                        }
                    }
                    // 2. Cargar Chats (Lógica del segundo código que muestra historial)
                    String sqlChats = "SELECT cp.id_chat, u2.id_usuario, u2.nombre, u2.foto, (SELECT mp.mensaje FROM mensaje_psicologo mp WHERE mp.id_chat = cp.id_chat ORDER BY mp.fecha DESC LIMIT 1) AS ultimo_mensaje " +
                                      "FROM chat_psicologo cp JOIN psicologo p ON cp.id_psicologo = p.id_psicologo JOIN usuario u2 ON p.id_usuario = u2.id_usuario WHERE cp.id_usuario = ? ORDER BY cp.id_chat DESC";
                    try (PreparedStatement ps2 = con.prepareStatement(sqlChats)) {
                        ps2.setInt(1, idLogueado);
                        try (ResultSet rs2 = ps2.executeQuery()) {
                            while (rs2.next()) {
                                misChats.add(new ChatLista(rs2.getInt("id_usuario"), rs2.getString("nombre"), procesarFoto(rs2.getString("foto")), rs2.getString("ultimo_mensaje") != null ? rs2.getString("ultimo_mensaje") : "Conversación iniciada", rs2.getInt("id_chat")));
                            }
                        }
                    }
                }
            } catch (Exception e) { e.printStackTrace(); }
        }
        request.setAttribute("listaPsicologos", listaPsicologos);
        request.setAttribute("misChats", misChats);
        request.getRequestDispatcher("pages/chat.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();
        String userMessage = request.getParameter("mensaje");

        if (API_KEY == null || API_KEY.isEmpty()) {
            out.print("Error: Configuración de IA faltante en el servidor.");
            return;
        }

        try {
            HttpURLConnection conn = (HttpURLConnection) new URL(GEMINI_URL + API_KEY).openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            conn.setDoOutput(true);

            String prompt = "Eres Serena, asistente de bienestar. Responde breve, empática, español, sin asteriscos ni markdown. Usuario dice: " + userMessage.replace("\"", "'");
            String jsonBody = "{\"contents\":[{\"parts\":[{\"text\":\"" + prompt + "\"}]}]}";

            try (OutputStream os = conn.getOutputStream()) { os.write(jsonBody.getBytes("utf-8")); }

            BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "utf-8"));
            StringBuilder res = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) res.append(line);
            
            // Extracción simple de texto
            String aiText = res.toString();
            if(aiText.contains("\"text\": \"")) {
                aiText = aiText.split("\"text\": \"")[1].split("\"")[0].replace("\\n", " ");
            }
            out.print(aiText);
        } catch (Exception e) {
            out.print("Lo siento, estoy teniendo un problema técnico. ¿Podemos intentarlo de nuevo?");
        }
    }

    private String procesarFoto(String foto) {
        if (foto == null || foto.trim().isEmpty()) return "https://img.icons8.com/3d-sugary/100/generic-user.png";
        if (foto.startsWith("http") || foto.startsWith("data:")) return foto;
        return "data:image/jpeg;base64," + foto;
    }
}