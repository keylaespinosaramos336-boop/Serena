package com.serena;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

// NOTA: Asegúrate de que estas clases existan en tu paquete com.serena
import com.serena.Psicologo; 
import com.serena.ChatLista;

@WebServlet(name = "ListarPsicologosServlet", urlPatterns = {"/ListarPsicologosServlet"})
public class ListarPsicologosServlet extends HttpServlet {

    // --- CONFIGURACIÓN DE CONEXIÓN ---
    private final String DB_URL = "jdbc:mysql://localhost:3306/bd_serena";
    private final String DB_USER = "root";
    private final String DB_PASS = "Keylabd2603";

    // --- CONFIGURACIÓN DE GEMINI API ---
    private static final String API_KEY = "AIzaSyAqQI6q-VKENwOQD8JIGg1eshdYYAu3naI";
    private static final String API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";

    /**
     * MÉTODO GET: Carga la página, los psicólogos disponibles y los chats abiertos.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        Integer idLogueado = (Integer) session.getAttribute("idUsuario");
        
        System.out.println("ID USUARIO: " + idLogueado);//DUDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        // Seguridad: Si no hay sesión, al login
        if (idLogueado == null) {
            System.out.println("ID REAL SESION: " + session.getAttribute("idUsuario"));
        }

        List<Psicologo> lista = new ArrayList<>();
        List<ChatLista> misChats = new ArrayList<>();

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
                
                // 1. Cargar Psicólogos
                String sqlPsico = "SELECT u.id_usuario, u.nombre, u.foto, p.cedula, p.especialidad, p.experiencia, p.modalidad  " +
                                 "FROM Usuario u INNER JOIN psicologo p ON u.id_usuario = p.id_usuario";
                PreparedStatement ps1 = con.prepareStatement(sqlPsico);
                ResultSet rs1 = ps1.executeQuery();
                while (rs1.next()) {
                    lista.add(new Psicologo(
                        rs1.getInt("id_usuario"),
                        rs1.getString("nombre"),
                        rs1.getString("especialidad"),
                        procesarFoto(rs1.getString("foto")), // 👈 AQUÍ VA LA FOTO
                        rs1.getString("experiencia"),
                        rs1.getString("cedula"),
                        rs1.getString("modalidad")
                    ));
                }

                // 2. Cargar Chats Activos (último mensaje)
                String sqlChats = 
                        "SELECT u2.id_usuario, u2.nombre, u2.foto, m.mensaje, c.id_chat " +
                        "FROM chat_psicologo c " +
                        "JOIN psicologo p ON c.id_psicologo = p.id_psicologo " +
                        "JOIN Usuario u2 ON p.id_usuario = u2.id_usuario " +
                        "LEFT JOIN mensaje_psicologo m ON c.id_chat = m.id_chat " +
                        "WHERE c.id_usuario = ? AND (m.id_mensaje = (SELECT MAX(id_mensaje) " +
                        "FROM mensaje_psicologo WHERE id_chat = c.id_chat) OR m.id_mensaje IS NULL)";

                
                PreparedStatement ps2 = con.prepareStatement(sqlChats);
                ps2.setInt(1, idLogueado);
                ResultSet rs2 = ps2.executeQuery();
                while (rs2.next()) {
                    misChats.add(new ChatLista(
                        rs2.getInt("id_usuario"), // 👈 ESTE ES EL ID DEL PSICÓLOGO
                        rs2.getString("nombre"),
                        procesarFoto(rs2.getString("foto")),
                        rs2.getString("mensaje") != null ? rs2.getString("mensaje") : "Conversación iniciada",
                        rs2.getInt("id_chat")
                    ));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        System.out.println("Psicologos: " + lista.size());//dudaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
        request.setAttribute("listaPsicologos", lista);
        request.setAttribute("misChats", misChats);
        
        // Redirige al JSP que centraliza la vista
        request.getRequestDispatcher("pages/chat.jsp").forward(request, response);
    }

    /**
     * MÉTODO POST: Recibe el mensaje del usuario desde AJAX y responde usando Serena (Gemini).
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String userMessage = request.getParameter("mensaje");

        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();

        if (userMessage == null || userMessage.trim().isEmpty()) {
            out.print("Hola, soy Serena. ¿En qué puedo apoyarte?");
            return;
        }

        try {
            URL url = new URL(API_URL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("X-goog-api-key", API_KEY);
            conn.setDoOutput(true);

            // Instrucciones de comportamiento para la IA
            String reglasSerena = "Eres Serena, asistente de bienestar. Responde de forma MUY BREVE (máximo 20 palabras), empática y directa.";
            String cleanUserMsg = userMessage.replace("\"", "'").replace("\n", " ");
            String promptFinal = reglasSerena + " El usuario dice: " + cleanUserMsg;

            // Construcción del JSON de envío
            String jsonInputString = "{\"contents\": [{\"parts\":[{\"text\": \"" + promptFinal + "\"}]}]}";

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonInputString.getBytes("utf-8");
                os.write(input, 0, input.length);
            }

            int status = conn.getResponseCode();
            InputStream is = (status < 400) ? conn.getInputStream() : conn.getErrorStream();

            StringBuilder apiResponse = new StringBuilder();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(is, "utf-8"))) {
                String line;
                while ((line = br.readLine()) != null) {
                    apiResponse.append(line.trim());
                }
            }

            String fullResponse = apiResponse.toString();

            if (status >= 400) {
                out.print("Lo siento, estoy teniendo un problema técnico. ¿Podemos intentarlo de nuevo?");
                return;
            }

            // Parseo manual del JSON para extraer el texto de respuesta
            String aiText = "No pude procesar la respuesta, pero estoy aquí para escucharte.";
            if (fullResponse.contains("\"text\": \"")) {
                int start = fullResponse.lastIndexOf("\"text\": \"") + 9;
                int end = fullResponse.indexOf("\"", start);
                if (start > 8 && end > start) {
                    aiText = fullResponse.substring(start, end);
                    // Corrección de caracteres especiales para español
                    aiText = aiText.replace("\\n", " ")
                                   .replace("\\\"", "\"")
                                   .replace("\\u00a1", "¡").replace("\\u00bf", "¿")
                                   .replace("\\u00f1", "ñ").replace("\\u00e1", "á")
                                   .replace("\\u00e9", "é").replace("\\u00ed", "í")
                                   .replace("\\u00f3", "ó").replace("\\u00fa", "ú");
                }
            }
            out.print(aiText);

        } catch (Exception e) {
            out.print("Error de conexión: " + e.getMessage());
        }
    }

    /**
     * MÉTODO AUXILIAR: Maneja las imágenes. 
     * Si no hay foto en la DB, devuelve la imagen por default de Serena.
     */
    private String procesarFoto(String fotoBase64) {
        // 1. Validar si es nulo o vacío
        if (fotoBase64 == null || fotoBase64.trim().isEmpty()) {
            // USAR UNA URL QUE NO CADUQUE
            return "https://img.icons8.com/3d-sugary/100/generic-user.png"; 
        }

        // 2. Si ya es una URL completa, la respetamos
        if (fotoBase64.startsWith("http")) {
            return fotoBase64;
        }

        // 3. Si es la cadena Base64 pura de la DB, le ponemos el prefijo para el navegador
        return "data:image/*;base64," + fotoBase64;
    }
}