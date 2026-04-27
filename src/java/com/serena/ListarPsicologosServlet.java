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

@WebServlet(name = "ListarPsicologosServlet", urlPatterns = {"/ListarPsicologosServlet"})
public class ListarPsicologosServlet extends HttpServlet {

    private final String DB_URL = System.getenv().getOrDefault(
        "DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway" +
        "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" +
        "&useUnicode=true&characterEncoding=UTF-8"
    );
    private final String DB_USER = System.getenv().getOrDefault("DB_USER", "root");
    private final String DB_PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    // ── Gemini ────────────────────────────────────────────────
    // FIX 3: modelo correcto actualizado (gemini-1.5-flash es el nombre estable)
    // CAMBIA ESTA LÍNEA POR ESTA:
    private static final String API_KEY = System.getenv("GEMINI_API_KEY");
    // Cambia tu constante a esta:
    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=";

    private static final String FOTO_DEFAULT = "https://img.icons8.com/3d-sugary/100/generic-user.png";

    // ══════════════════════════════════════════════════════════
    //  GET: carga psicólogos + chats activos → chatTrabajador.jsp
    // ══════════════════════════════════════════════════════════
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Integer idLogueado = (session != null) ? (Integer) session.getAttribute("idUsuario") : null;

        List<Psicologo> listaPsicologos = new ArrayList<>();
        List<ChatLista> misChats        = new ArrayList<>();

        if (idLogueado != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

                    // 1. Cargar todos los psicólogos
                    String sqlPsico =
                        "SELECT u.id_usuario, u.nombre, u.foto, " +
                        "       p.cedula, p.especialidad, p.experiencia, p.modalidad " +
                        "FROM usuario u " +
                        "INNER JOIN psicologo p ON u.id_usuario = p.id_usuario";
                    try (PreparedStatement ps1 = con.prepareStatement(sqlPsico);
                         ResultSet rs1 = ps1.executeQuery()) {
                        while (rs1.next()) {
                            listaPsicologos.add(new Psicologo(
                                rs1.getInt("id_usuario"),
                                rs1.getString("nombre"),
                                rs1.getString("especialidad"),
                                procesarFoto(rs1.getString("foto")),
                                rs1.getString("experiencia"),
                                rs1.getString("cedula"),
                                rs1.getString("modalidad")
                            ));
                        }
                    }

                    // 2. Cargar chats activos del trabajador
                    // FIX 2: incluimos cp.id_chat directamente para pasarlo al JSP
                    String sqlChats =
                        "SELECT cp.id_chat, " +
                        "       u2.id_usuario, u2.nombre, u2.foto, " +
                        "       (SELECT mp.mensaje FROM mensaje_psicologo mp " +
                        "        WHERE mp.id_chat = cp.id_chat " +
                        "        ORDER BY mp.fecha DESC LIMIT 1) AS ultimo_mensaje " +
                        "FROM chat_psicologo cp " +
                        "JOIN psicologo p ON cp.id_psicologo = p.id_psicologo " +
                        "JOIN usuario u2 ON p.id_usuario = u2.id_usuario " +
                        "WHERE cp.id_usuario = ? " +
                        "ORDER BY cp.id_chat DESC";

                    try (PreparedStatement ps2 = con.prepareStatement(sqlChats)) {
                        ps2.setInt(1, idLogueado);
                        try (ResultSet rs2 = ps2.executeQuery()) {
                            while (rs2.next()) {
                                String ultMsg = rs2.getString("ultimo_mensaje");
                                misChats.add(new ChatLista(
                                    rs2.getInt("id_usuario"),       // id_usuario del psicólogo
                                    rs2.getString("nombre"),
                                    procesarFoto(rs2.getString("foto")),
                                    ultMsg != null ? ultMsg : "Conversacion iniciada",
                                    rs2.getInt("id_chat")           // id_chat real de la BD
                                ));
                            }
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        request.setAttribute("listaPsicologos", listaPsicologos);
        request.setAttribute("misChats", misChats);
        request.getRequestDispatcher("pages/chat.jsp").forward(request, response);
    }

    // ══════════════════════════════════════════════════════════
    //  POST: respuesta de la IA Gemini
    // ══════════════════════════════════════════════════════════
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String userMessage = request.getParameter("mensaje");
        if (userMessage == null || userMessage.trim().isEmpty()) {
            out.print("Hola, soy Serena. ¿En qué puedo apoyarte?");
            return;
        }

        try {
            // FIX 3: URL correcta con la API key como query param
            String fullUrl = GEMINI_URL + API_KEY;
            URL url = new URL(fullUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(15000);
            conn.setDoOutput(true);

            // Prompt con instrucciones de comportamiento
            String reglasSerena =
                "Eres Serena, asistente de bienestar mental. " +
                "Responde de forma BREVE (maximo 30 palabras), empatica y en espanol. " +
                "No uses markdown ni asteriscos. Solo texto plano.";
            String cleanMsg   = userMessage.replace("\\", "\\\\")
                                           .replace("\"", "'")
                                           .replace("\n", " ")
                                           .replace("\r", " ");
            String promptFinal = reglasSerena + " El usuario dice: " + cleanMsg;

            // FIX 3: JSON con system instruction separado para mejor comportamiento
            String jsonBody =
                "{\"contents\":[{\"parts\":[{\"text\":\"" + promptFinal + "\"}]}]," +
                "\"generationConfig\":{\"maxOutputTokens\":80,\"temperature\":0.7}}";

            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes("utf-8"));
            }

            int status = conn.getResponseCode();

            // FIX 3: leer tanto éxito como error
            InputStream is = null;
            try {
                is = (status < 400) ? conn.getInputStream() : conn.getErrorStream();
            } catch (Exception eStream) {
                out.print("Lo siento, no pude conectarme. ¿Intentamos de nuevo?");
                return;
            }

            if (is == null) {
                out.print("Lo siento, la respuesta estuvo vacía. ¿Puedes repetir?");
                return;
            }

            StringBuilder apiResponse = new StringBuilder();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(is, "utf-8"))) {
                String line;
                while ((line = br.readLine()) != null) {
                    apiResponse.append(line.trim());
                }
            }

            String fullResponse = apiResponse.toString();

            if (status >= 400) {
                System.err.println("[Gemini ERROR " + status + "] " + fullResponse);
                out.print("Lo siento, estoy teniendo un problema técnico. ¿Podemos intentarlo de nuevo?");
                return;
            }

            // Parseo manual: buscar "text": "..."
            String aiText = "Estoy aquí para escucharte. ¿Cómo te sientes?";
            String marker = "\"text\":\"";
            int idx = fullResponse.lastIndexOf(marker);
            if (idx >= 0) {
                int start = idx + marker.length();
                // Buscar cierre de comilla no escapada
                int end = start;
                while (end < fullResponse.length()) {
                    char c = fullResponse.charAt(end);
                    if (c == '"' && fullResponse.charAt(end - 1) != '\\') break;
                    end++;
                }
                if (end > start) {
                    aiText = fullResponse.substring(start, end);
                    // Limpiar escapes
                    aiText = aiText.replace("\\n",  " ")
                                   .replace("\\\"", "\"")
                                   .replace("\\\\", "\\")
                                   .replace("\\u00a1","¡").replace("\\u00bf","¿")
                                   .replace("\\u00f1","ñ").replace("\\u00e1","á")
                                   .replace("\\u00e9","é").replace("\\u00ed","í")
                                   .replace("\\u00f3","ó").replace("\\u00fa","ú")
                                   .replace("\\u00c1","Á").replace("\\u00c9","É")
                                   .replace("\\u00cd","Í").replace("\\u00d3","Ó")
                                   .replace("\\u00da","Ú").replace("\\u00d1","Ñ")
                                   .replace("\\*","").replace("**","").replace("*","");
                }
            }

            out.print(aiText);

        } catch (java.net.SocketTimeoutException te) {
            out.print("La respuesta tardó demasiado. ¿Lo intentamos de nuevo?");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("Ocurrió un error inesperado. Por favor intenta de nuevo.");
        }
    }

    // ── Helper: foto siempre con valor ─────────────────────────
    private String procesarFoto(String foto) {
        if (foto == null || foto.trim().isEmpty()) {
            return FOTO_DEFAULT;
        }
        if (foto.startsWith("http") || foto.startsWith("data:")) {
            return foto;
        }
        // Base64 puro de BD
        return "data:image/jpeg;base64," + foto;
    }
}
