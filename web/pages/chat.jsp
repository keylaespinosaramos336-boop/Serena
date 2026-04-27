<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.serena.Psicologo" %>
<%@ page import="com.serena.ChatLista" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Chat - Serena</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">

    <style>
        body {
            margin: 0;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            background: #e6e6e6;
            font-family: 'Plus Jakarta Sans', sans-serif;
        }

        /* MARCO TELEFONO */
        .phone-frame {
            width: 380px;
            height: 760px;
            background: black;
            border-radius: 50px;
            padding: 15px;
            box-shadow: 0 30px 60px rgba(0,0,0,0.4);
            display: flex;
            justify-content: center;
            align-items: center;
        }

        /* PANTALLA */
        .phone {
            width: 340px;
            height: 680px;
            background: linear-gradient(180deg,#6aa3d6,#3f6ba9);
            border-radius: 40px;
            overflow: hidden;
            color: white;
            position: relative;
            display: flex;
            flex-direction: column;
        }

        .notch {
            width: 120px;
            height: 25px;
            background: black;
            border-radius: 0 0 20px 20px;
            position: absolute;
            top: 0;
            left: 50%;
            transform: translateX(-50%);
            z-index: 10;
        }

        /* CONTENIDO CHAT */
        .content {
            flex: 1;
            padding: 30px 0 90px 0;
            overflow-y: auto;
            scrollbar-width: none;
        }
        .content::-webkit-scrollbar { display: none; }

        .section-title {
            font-size: 15px;
            font-weight: 700;
            margin: 15px 15px 12px 15px;
        }

        /* PSICOLOGOS EN LÍNEA */
        .online-row {
            display: flex;
            gap: 15px;
            padding: 0 15px;
            margin-bottom: 20px;
            overflow-x: auto;
            scrollbar-width: none;
        }
        .online-row::-webkit-scrollbar { display: none; }

        .online-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            min-width: 60px;
        }

        .avatar-wrapper {
            position: relative;
            width: 55px;
            height: 55px;
            margin-bottom: 5px;
        }

        /* FIX 1: foto psicólogo siempre ocupa el círculo */
        .avatar-img {
            width: 100%;
            height: 100%;
            border-radius: 50%;
            object-fit: cover;
            background: #ddd;
            display: block;
        }

        .active-dot {
            position: absolute;
            bottom: 2px;
            right: 2px;
            width: 12px;
            height: 12px;
            background: #4cd137;
            border: 2px solid #6aa3d6;
            border-radius: 50%;
        }

        .online-name {
            font-size: 10px;
            opacity: 0.9;
            text-align: center;
        }

        /* LISTA DE CHATS */
        .chat-list { padding: 0 15px; }

        .chat-item {
            display: flex;
            align-items: center;
            margin-bottom: 8px;
            cursor: pointer;
            background: rgba(255, 255, 255, 0.1);
            padding: 10px;
            border-radius: 15px;
            transition: 0.2s;
        }
        .chat-item:hover { background: rgba(255,255,255,0.2); }

        /* FIX 1: avatar de chat con imagen siempre bien */
        .chat-avatar-mini {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            margin-right: 12px;
            background: rgba(255,255,255,0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            flex-shrink: 0;
            overflow: hidden;
        }
        .chat-avatar-mini img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 50%;
            display: block;
        }

        .chat-info { flex: 1; min-width: 0; }
        .chat-name { font-weight: 600; font-size: 14px; }
        .chat-last {
            opacity: 0.8;
            font-size: 12px;
            margin-top: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 180px;
        }

        /* SUGERENCIAS DE CONTACTO */
        .suggestions-scroll {
            display: flex;
            gap: 12px;
            padding: 0 15px 20px 15px;
            overflow-x: auto;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }
        .suggestions-scroll::-webkit-scrollbar { display: none; }

        .suggestion-card {
            min-width: 140px;
            background: white;
            border-radius: 15px;
            padding: 15px;
            text-align: center;
            color: #333;
        }

        /* FIX 1: foto en tarjeta de sugerencia */
        .suggestion-card img {
            width: 65px;
            height: 65px;
            border-radius: 50%;
            margin-bottom: 10px;
            object-fit: cover;
            border: 2px solid #eee;
            display: block;
            margin-left: auto;
            margin-right: auto;
            background: #eee;
        }

        .suggestion-name {
            font-size: 13px;
            font-weight: 700;
            margin-bottom: 10px;
            display: block;
        }

        .btn-contact {
            background: #4c6ef5;
            color: white;
            border: none;
            padding: 6px 0;
            width: 100%;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 600;
            cursor: pointer;
        }

        .btn-profile {
            background: #f1f3f5;
            color: #444;
            border: none;
            padding: 6px 0;
            width: 100%;
            border-radius: 8px;
            font-size: 11px;
            margin-top: 5px;
            cursor: pointer;
        }

        /* MENÚ INFERIOR */
        .menu {
            position: absolute;
            bottom: 0;
            width: 100%;
            height: 70px;
            background: rgba(0, 0, 0, 0.504);
            display: flex;
            justify-content: space-around;
            align-items: center;
            font-size: 12px;
        }

        .menu div {
            text-align: center;
            cursor: pointer;
            padding: 8px 10px;
            border-radius: 12px;
            transition: 0.2s;
        }

        .menu .active {
            background: rgba(255,255,255,0.25);
            transform: scale(1.05);
            font-weight: bold;
        }

        /* MODAL CHAT */
        .chat-modal {
            display: none;
            position: absolute;
            top: 40px;
            left: 10px;
            right: 10px;
            bottom: 80px;
            background: #fdfdfd;
            border-radius: 20px;
            z-index: 100;
            flex-direction: column;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            color: #333;
            overflow: hidden;
        }

        .chat-header {
            background: #4c6ef5;
            color: white;
            padding: 12px 15px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 14px;
            font-weight: 600;
            flex-shrink: 0;
        }

        /* ÁREA DE MENSAJES */
        .chat-box {
            flex: 1;
            padding: 20px;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
            gap: 12px;
            background: #fafafc;
            scrollbar-width: none;
        }
        .chat-box::-webkit-scrollbar { display: none; }

        .msg {
            max-width: 75%;
            padding: 12px 18px;
            border-radius: 18px;
            font-size: 13px;
            line-height: 1.5;
            position: relative;
            word-wrap: break-word;
            text-shadow: none !important;
        }

        /* mis mensajes = derecha azul */
        .msg.user {
            align-self: flex-end;
            background: #4c6ef5;
            color: white;
            border-bottom-right-radius: 4px;
        }

        /* mensajes del psicólogo / IA = izquierda blanco */
        .msg.bot {
            align-self: flex-start;
            background: white;
            color: #333;
            border-bottom-left-radius: 4px;
            border: 1px solid #eee;
            box-shadow: 0 2px 5px rgba(0,0,0,0.03);
        }

        /* hora del mensaje */
        .msg-time {
            font-size: 9px;
            opacity: 0.55;
            margin-top: 3px;
            display: block;
            text-align: right;
        }
        .msg.bot .msg-time { text-align: left; }

        /* ÁREA DE ENTRADA */
        .chat-input-area {
            padding: 15px;
            display: flex;
            gap: 10px;
            border-top: 1px solid #eee;
            background: white;
            flex-shrink: 0;
        }

        .chat-input-area input {
            flex: 1;
            border: 1px solid #ddd;
            border-radius: 20px;
            padding: 10px 18px;
            outline: none;
            font-size: 13px;
            font-family: 'Plus Jakarta Sans', sans-serif;
        }
        .chat-input-area input:focus { border-color: #4c6ef5; }

        .chat-input-area button {
            background: #4c6ef5;
            color: white;
            border: none;
            width: 38px;
            height: 38px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 15px;
        }

        /* ANIMACIÓN ESCRIBIENDO */
        #typing-bubble {
            display: flex;
            align-items: center;
            gap: 5px;
            width: fit-content;
            padding: 12px 18px;
            background: #f1f3f5;
            border-radius: 18px 18px 18px 4px;
            border: 1px solid #eee;
            box-shadow: none !important;
            text-shadow: none !important;
        }

        .dot {
            width: 8px;
            height: 8px;
            background-color: #4c6ef5 !important;
            border-radius: 50%;
            display: inline-block;
            border: none !important;
            box-shadow: none !important;
            animation: bounce-serena 1.3s infinite ease-in-out;
        }
        .dot:nth-child(2) { animation-delay: -1.1s; }
        .dot:nth-child(3) { animation-delay: -0.9s; }

        @keyframes bounce-serena {
            0%, 60%, 100% { transform: translateY(0); opacity: 0.4; }
            30% { transform: translateY(-6px); opacity: 1; }
        }

        /* MODAL PERFIL */
        .profile-modal-content {
            background: #ffffff;
            height: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            color: #333;
        }

        .profile-header-custom {
            padding: 35px 20px 20px 20px;
            text-align: center;
        }

        #profileImg {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            border: 4px solid rgba(255,255,255,0.3);
            object-fit: cover;
            margin-bottom: 15px;
            background: #ddd;
        }

        .profile-info-container {
            width: 90%;
            background: #f4f7f9;
            border-radius: 25px 25px 0 0;
            padding: 20px;
            flex: 1;
            overflow-y: auto;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }
        .profile-info-container::-webkit-scrollbar { display: none; }

        .info-label {
            font-size: 17px;
            font-weight: 800;
            margin-bottom: 15px;
            display: block;
            color: #2d4e83;
        }

        .info-card {
            background: white;
            border-radius: 15px;
            padding: 12px 15px;
            margin-bottom: 10px;
            border: 1px solid #d0dae5;
            box-shadow: 0 5px 10px rgba(0,0,0,0.05);
        }

        .info-card strong {
            display: block;
            font-size: 14px;
            margin-bottom: 4px;
            opacity: 0.9;
        }

        .info-card span {
            font-size: 13px;
            font-weight: 400;
            line-height: 1.4;
            display: block;
        }

        .close-profile-btn {
            position: absolute;
            top: 15px;
            right: 20px;
            background: #f0f4f8;
            border: none;
            color: #2d4e83;
            font-size: 20px;
            border-radius: 50%;
            width: 35px;
            height: 35px;
            cursor: pointer;
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>

<div class="phone-frame">
    <div class="phone">
        <div class="notch"></div>
        <div class="content">

            <!-- EN LÍNEA -->
            <div class="section-title">En línea ahora</div>
            <div class="online-row">
                <%
                    List<Psicologo> psicologosOnline = (List<Psicologo>) request.getAttribute("listaPsicologos");
                    String defaultFoto = "https://img.icons8.com/3d-sugary/100/generic-user.png";
                    if (psicologosOnline != null && !psicologosOnline.isEmpty()) {
                        for (Psicologo po : psicologosOnline) {
                            // FIX 1: foto siempre tiene valor
                            String fotoOnline = (po.getFoto() != null && !po.getFoto().trim().isEmpty())
                                ? po.getFoto() : defaultFoto;
                            String primerNombre = po.getNombre() != null
                                ? po.getNombre().split(" ")[0] : "Psicologo";
                %>
                <div class="online-item">
                    <div class="avatar-wrapper">
                        <img src="<%= fotoOnline %>"
                             class="avatar-img"
                             onerror="this.src='<%= defaultFoto %>'"
                             alt="">
                        <div class="active-dot"></div>
                    </div>
                    <span class="online-name"><%= primerNombre %></span>
                </div>
                <%      }
                    } else { %>
                <div style="font-size:11px;opacity:.7;padding:10px 0;">Sin psicólogos disponibles</div>
                <% } %>
            </div>

            <!-- MENSAJES -->
            <div class="section-title">Mensajes</div>
            <div class="chat-list" id="listaConversaciones">

                <!-- Chat IA siempre presente -->
                <div class="chat-item" onclick="openChat('Asistente Serena')">
                    <div class="chat-avatar-mini">
                        <img src="https://img.icons8.com/color/48/ai-robot--v11.png" alt="Serena">
                    </div>
                    <div class="chat-info">
                        <div class="chat-name">Asistente Serena</div>
                        <div class="chat-last">&#161;Hola! &#191;C&#243;mo te sientes hoy?</div>
                    </div>
                </div>

                <%
                    List<ChatLista> misChats = (List<ChatLista>) request.getAttribute("misChats");
                    if (misChats != null) {
                        for (ChatLista chat : misChats) {
                            // FIX 1: foto psicólogo con fallback
                            String fotoChatPsico = (chat.getFoto() != null && !chat.getFoto().trim().isEmpty())
                                ? chat.getFoto() : defaultFoto;
                            String nombreEsc = chat.getNombre().replace("'", "\\'");
                            String fotoEsc   = fotoChatPsico.replace("'", "\\'").replace("\"","&quot;");
                %>
                <div class="chat-item"
                     onclick="openChatPsicologo('<%= nombreEsc %>', <%= chat.getIdPsicologo() %>, '<%= fotoEsc %>', <%= chat.getIdChat() %>)">
                    <div class="chat-avatar-mini">
                        <img src="<%= fotoChatPsico %>"
                             onerror="this.src='<%= defaultFoto %>'"
                             alt="<%= chat.getNombre() %>">
                    </div>
                    <div class="chat-info">
                        <div class="chat-name"><%= chat.getNombre() %></div>
                        <div class="chat-last"><%= chat.getUltimoMensaje() %></div>
                    </div>
                </div>
                <%      }
                    }
                %>
            </div>

            <!-- PSICÓLOGOS QUE PODRÍAS CONTACTAR -->
            <div class="section-title">Psic&#243;logos que podr&#237;as contactar</div>

            <%
                List<Psicologo> psicologos = (List<Psicologo>) request.getAttribute("listaPsicologos");
            %>

            <div class="suggestions-scroll">
                <%
                    if (psicologos != null && !psicologos.isEmpty()) {
                        for (Psicologo p : psicologos) {
                            // FIX 1: foto siempre con valor
                            String fotoData = p.getFoto();
                            String imgSrc = (fotoData != null && !fotoData.trim().isEmpty())
                                ? fotoData : defaultFoto;

                            String nombre      = p.getNombre()      != null ? p.getNombre().replace("'","\\'")      : "Psicologo";
                            String especialidad= p.getEspecialidad()!= null ? p.getEspecialidad().replace("'","\\'") : "General";
                            String experiencia = p.getExperiencia() != null ? p.getExperiencia().replace("'","\\'")  : "";
                            String cedula      = p.getCedula()      != null ? p.getCedula().replace("'","\\'")       : "";
                            String modalidad   = p.getModalidad()   != null ? p.getModalidad().replace("'","\\'")    : "";
                            String imgSrcEsc   = imgSrc.replace("'","\\'");
                %>
                <div class="suggestion-card">
                    <img src="<%= imgSrc %>"
                         onerror="this.src='<%= defaultFoto %>'"
                         alt="Foto de perfil">
                    <span class="suggestion-name"><%= p.getNombre() %></span>
                    <button class="btn-contact"
                            onclick="openChatPsicologo('<%= nombre %>', <%= p.getId() %>, '<%= imgSrcEsc %>', 0)">
                        Contactar
                    </button>
                    <button class="btn-profile"
                            onclick="openProfile('<%= nombre %>','<%= imgSrcEsc %>','<%= especialidad %>','<%= experiencia %>','<%= cedula %>','<%= modalidad %>')">
                        Ver perfil
                    </button>
                </div>
                <%      }
                    } else { %>
                <p style="padding:20px;font-size:12px;color:white;text-align:center;width:100%;">
                    No hay psic&#243;logos disponibles en este momento
                </p>
                <% } %>
            </div>
        </div><!-- /content -->

        <!-- MENÚ -->
        <div class="menu">
            <div onclick="location.href='${pageContext.request.contextPath}/pages/homeTrabajador.jsp'">&#127968;<br>Inicio</div>
            <div onclick="location.href='${pageContext.request.contextPath}/pages/sueno.jsp'">&#127769;<br>Sue&#241;o</div>
            <div onclick="location.href='${pageContext.request.contextPath}/pages/meditar.jsp'">&#129496;<br>Meditar</div>
            <div onclick="location.href='${pageContext.request.contextPath}/pages/audios.jsp'">&#127925;<br>Audios</div>
            <div class="active" onclick="location.href='${pageContext.request.contextPath}/ListarPsicologosServlet'">&#128172;<br>Chat</div>
            <div onclick="location.href='${pageContext.request.contextPath}/pages/perfil.jsp'">&#128100;<br>Perfil</div>
        </div>

        <!-- MODAL CHAT -->
        <div id="chatModal" class="chat-modal">
            <div class="chat-header">
                <div style="display:flex;align-items:center;gap:10px;">
                    <img id="chatHeaderFoto"
                         src="https://img.icons8.com/color/48/ai-robot--v11.png"
                         style="width:32px;height:32px;border-radius:50%;object-fit:cover;border:2px solid rgba(255,255,255,0.4);"
                         onerror="this.src='https://img.icons8.com/3d-sugary/100/generic-user.png'">
                    <span id="chatTargetName">Asistente Serena</span>
                </div>
                <button onclick="closeChat()"
                        style="background:none;border:none;color:white;font-size:20px;cursor:pointer;">&#10005;</button>
            </div>

            <div id="chatBox" class="chat-box">
                <div class="msg bot">&#161;Hola! &#191;En qu&#233; puedo ayudarte hoy?</div>
            </div>

            <div class="chat-input-area">
                <input type="text" id="userInput"
                       placeholder="Escribe un mensaje..."
                       onkeypress="handleKeyPress(event)">
                <button onclick="sendMessage()">&#10148;</button>
            </div>
        </div>

        <!-- MODAL PERFIL -->
        <div id="profileModal" class="chat-modal">
            <button class="close-profile-btn" onclick="closeProfile()">&#10005;</button>
            <div class="profile-modal-content">
                <div class="profile-header-custom">
                    <img id="profileImg" src="" alt="Foto de perfil"
                         onerror="this.src='https://img.icons8.com/3d-sugary/100/generic-user.png'">
                    <h2 id="profileName" style="margin:0;font-size:22px;"></h2>
                    <p id="profileRole" style="margin:5px 0;opacity:0.8;font-size:14px;"></p>
                </div>
                <div class="profile-info-container">
                    <span class="info-label">Informaci&#243;n profesional</span>
                    <div class="info-card">
                        <strong>C&#233;dula profesional:</strong>
                        <span id="profileLic"></span>
                    </div>
                    <div class="info-card">
                        <strong>Especialidad:</strong>
                        <span id="profileEsp"></span>
                    </div>
                    <div class="info-card">
                        <strong>Experiencia:</strong>
                        <span id="profileExp"></span>
                    </div>
                    <div class="info-card">
                        <strong>Modalidad:</strong>
                        <span id="profileMod"></span>
                    </div>
                </div>
            </div>
        </div>

    </div><!-- /phone -->
</div><!-- /phone-frame -->

<script>
    // ── Variables globales ─────────────────────────────────────
    var typingIndicator  = null;
    var idPsicologoActual = null; // null = IA, number = psicólogo real
    var idChatActual      = 0;    // id_chat en BD
    var fotoPsicActual    = '';
    var pollingInterval   = null;
    var ultimoIdMsg       = 0;

    // Rutas de servlets (sin backticks para evitar error EL de JSP)
    var SERVLET_IA    = '<%= request.getContextPath() %>/ListarPsicologosServlet';
    var SERVLET_PSICO = '<%= request.getContextPath() %>/MensajePsicologoSerlvet';
    var SERVLET_CHAT  = '<%= request.getContextPath() %>/ChatPsicologoServlet'; // GET mensajes
    var DEFAULT_FOTO  = 'https://img.icons8.com/3d-sugary/100/generic-user.png';
    var ROBOT_FOTO    = 'https://img.icons8.com/color/48/ai-robot--v11.png';

    // ── Abrir chat IA ──────────────────────────────────────────
    function openChat(name) {
        idPsicologoActual = null;
        idChatActual      = 0;
        fotoPsicActual    = ROBOT_FOTO;

        document.getElementById('chatTargetName').innerText = name;
        document.getElementById('chatHeaderFoto').src       = ROBOT_FOTO;
        document.getElementById('chatModal').style.display  = 'flex';

        // Chat IA: solo mensaje de bienvenida, no carga BD
        var box = document.getElementById('chatBox');
        box.innerHTML = '';
        agregarBurbuja('bot', '¡Hola! ¿En qué puedo ayudarte hoy?', '');

        if (pollingInterval) { clearInterval(pollingInterval); pollingInterval = null; }
    }

    // ── Abrir chat con psicólogo ───────────────────────────────
    // FIX 2: ahora recibe idChat y carga mensajes reales desde la BD
    function openChatPsicologo(nombre, idPsicologo, foto, idChat) {
        idPsicologoActual = idPsicologo;
        idChatActual      = idChat;
        fotoPsicActual    = (foto && foto.length > 5) ? foto : DEFAULT_FOTO;
        ultimoIdMsg       = 0;

        document.getElementById('chatTargetName').innerText = nombre;
        document.getElementById('chatHeaderFoto').src       = fotoPsicActual;
        document.getElementById('chatModal').style.display  = 'flex';

        var box = document.getElementById('chatBox');
        box.innerHTML = '<div style="text-align:center;font-size:11px;color:#aaa;padding:20px;">Cargando mensajes...</div>';

        // Si ya existe un chat, cargar historial
        if (idChat > 0) {
            cargarHistorialPsicologo(true);
            // Polling cada 3s para ver si el psicólogo responde
            if (pollingInterval) clearInterval(pollingInterval);
            pollingInterval = setInterval(function() { cargarHistorialPsicologo(false); }, 3000);
        } else {
            box.innerHTML = '<div style="text-align:center;font-size:11px;color:#aaa;padding:20px;">Escribe tu primer mensaje</div>';
        }
    }

    // ── FIX 2: Cargar historial real desde BD ──────────────────
    function cargarHistorialPsicologo(completo) {
        if (!idChatActual || idChatActual <= 0) return;
        var desde = completo ? 0 : ultimoIdMsg;
        var url   = SERVLET_CHAT + '?accion=getMensajes&idChat=' + idChatActual + '&desde=' + desde;

        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.onload = function() {
            if (xhr.status !== 200) return;
            var data;
            try { data = JSON.parse(xhr.responseText); } catch(e) { return; }

            var box = document.getElementById('chatBox');
            if (completo) {
                box.innerHTML = '';
                if (data.length === 0) {
                    box.innerHTML = '<div style="text-align:center;font-size:11px;color:#aaa;padding:20px;">Sin mensajes aun. Escribe el primero.</div>';
                    return;
                }
            }

            var nuevos = false;
            for (var i = 0; i < data.length; i++) {
                var msg = data[i];
                if (msg.id > ultimoIdMsg) {
                    ultimoIdMsg = msg.id;
                    // Los mensajes del 'usuario' son del trabajador = lado derecho (user)
                    // Los mensajes del 'psicologo' son del psicólogo = lado izquierdo (bot)
                    var lado = (msg.remitente === 'usuario') ? 'user' : 'bot';
                    agregarBurbuja(lado, msg.mensaje, msg.hora);
                    nuevos = true;
                }
            }
            if (nuevos || completo) box.scrollTop = box.scrollHeight;
        };
        xhr.send();
    }

    // ── Cerrar chat ────────────────────────────────────────────
    function closeChat() {
        document.getElementById('chatModal').style.display = 'none';
        if (pollingInterval) { clearInterval(pollingInterval); pollingInterval = null; }
        idPsicologoActual = null;
        idChatActual      = 0;
    }

    function handleKeyPress(e) {
        if (e.key === 'Enter') sendMessage();
    }

    // ── Enviar mensaje ─────────────────────────────────────────
    function sendMessage() {
        var input   = document.getElementById('userInput');
        var message = input.value.trim();
        if (!message || input.disabled) return;

        input.value    = '';
        input.disabled = true;

        // Mostrar mensaje del usuario de inmediato
        agregarBurbuja('user', message, horaActual());

        if (idPsicologoActual === null) {
            // ── FIX 3: Chat IA con Gemini ──────────────────────
            showTyping();
            var xhr  = new XMLHttpRequest();
            var body = 'mensaje=' + encodeURIComponent(message);
            xhr.open('POST', SERVLET_IA, true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                removeTyping();
                var txt = xhr.responseText || 'Lo siento, no pude responder.';
                // Si el servlet devuelve un error HTTP o texto de error técnico,
                // mostramos mensaje amigable
                if (xhr.status >= 400 || txt.indexOf('Exception') >= 0) {
                    txt = 'Lo siento, estoy teniendo dificultades técnicas. ¿Puedes intentarlo de nuevo?';
                }
                agregarBurbuja('bot', txt, horaActual());
                input.disabled = false;
                input.focus();
            };
            xhr.onerror = function() {
                removeTyping();
                agregarBurbuja('bot', 'Error de conexión con el servidor.', horaActual());
                input.disabled = false;
            };
            xhr.send(body);

        } else {
            // ── Chat con psicólogo real ────────────────────────
            var xhr  = new XMLHttpRequest();
            var body = 'mensaje=' + encodeURIComponent(message) +
                       '&idPsicologo=' + idPsicologoActual;
            xhr.open('POST', SERVLET_PSICO, true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                var txt = xhr.responseText;
                if (txt && txt.indexOf('Error') === 0) {
                    agregarBurbuja('bot', 'Sistema: ' + txt, horaActual());
                } else if (txt === 'Enviado') {
                    // Mensaje guardado OK. Si no había idChat, recargar la página
                    // para que aparezca en la lista y obtener el nuevo idChat
                    if (idChatActual <= 0) {
                        setTimeout(function() { location.reload(); }, 800);
                    } else {
                        // Actualizar último mensaje en lista
                        actualizarListaChats();
                    }
                }
                input.disabled = false;
                input.focus();
            };
            xhr.onerror = function() {
                agregarBurbuja('bot', 'Error de conexión.', horaActual());
                input.disabled = false;
            };
            xhr.send(body);
        }
    }

    // ── Crear burbuja sin innerHTML con datos del usuario ──────
    function agregarBurbuja(lado, texto, hora) {
        var box  = document.getElementById('chatBox');
        var div  = document.createElement('div');
        div.className = 'msg ' + lado;

        var textoNodo = document.createTextNode(texto);
        div.appendChild(textoNodo);

        if (hora) {
            var span = document.createElement('span');
            span.className   = 'msg-time';
            span.textContent = hora;
            div.appendChild(span);
        }

        box.appendChild(div);
        box.scrollTop = box.scrollHeight;
    }

    // ── Typing dots ────────────────────────────────────────────
    function showTyping() {
        var box = document.getElementById('chatBox');
        typingIndicator    = document.createElement('div');
        typingIndicator.id = 'typing-bubble';
        typingIndicator.innerHTML =
            '<span class="dot"></span><span class="dot"></span><span class="dot"></span>';
        box.appendChild(typingIndicator);
        box.scrollTop = box.scrollHeight;
    }

    function removeTyping() {
        if (typingIndicator) { typingIndicator.remove(); typingIndicator = null; }
    }

    // ── Modal perfil ───────────────────────────────────────────
    function openProfile(nombre, foto, especialidad, experiencia, cedula, modalidad) {
        document.getElementById('profileName').innerText = nombre;
        document.getElementById('profileImg').src        = foto || DEFAULT_FOTO;
        document.getElementById('profileEsp').innerText  = especialidad  || 'No disponible';
        document.getElementById('profileExp').innerText  = experiencia   || 'No disponible';
        document.getElementById('profileLic').innerText  = cedula        || 'No disponible';
        document.getElementById('profileMod').innerText  = modalidad     || 'No disponible';
        document.getElementById('profileModal').style.display = 'flex';
    }

    function closeProfile() {
        document.getElementById('profileModal').style.display = 'none';
    }

    // ── Hora actual ────────────────────────────────────────────
    function horaActual() {
        var d = new Date();
        return ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2);
    }

    // ── Actualizar lista de conversaciones ─────────────────────
    function actualizarListaChats() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', window.location.href, true);
        xhr.onload = function() {
            if (xhr.status !== 200) return;
            var doc   = new DOMParser().parseFromString(xhr.responseText, 'text/html');
            var nueva = doc.getElementById('listaConversaciones');
            if (nueva) document.getElementById('listaConversaciones').innerHTML = nueva.innerHTML;
        };
        xhr.send();
    }

    // Refrescar lista cada 5s para ver respuestas nuevas del psicólogo
    setInterval(actualizarListaChats, 5000);
</script>

</body>
</html>
