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
            body{
              margin:0;
              height:100vh;
              display:flex;
              justify-content:center;
              align-items:center;
              background:#e6e6e6;
              font-family:'Plus Jakarta Sans', sans-serif;
            }

            /* MARCO TELEFONO */
            .phone-frame{
              width:380px;
              height:760px;
              background:black;
              border-radius:50px;
              padding:15px;
              box-shadow:0 30px 60px rgba(0,0,0,0.4);
              display:flex;
              justify-content:center;
              align-items:center;
            }

            /* PANTALLA */
            .phone{
              width:340px;
              height:680px;
              background:linear-gradient(180deg,#6aa3d6,#3f6ba9);
              border-radius:40px;
              overflow:hidden;
              color:white;
              position:relative;
              display:flex;
              flex-direction:column;
            }

            .notch{
              width:120px;
              height:25px;
              background:black;
              border-radius:0 0 20px 20px;
              position:absolute;
              top:0;
              left:50%;
              transform:translateX(-50%);
              z-index:10;
            }

            /* CONTENIDO CHAT */
            .content{
              flex:1;
              padding:30px 0 90px 0;
              overflow-y:auto;
              scrollbar-width: none;
            }
            .content::-webkit-scrollbar { display: none; }

            .section-title{
              font-size:15px;
              font-weight:700;
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

            .avatar-img {
                width: 100%;
                height: 100%;
                border-radius: 50%;
                object-fit: cover;
                background: white;
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

            .chat-avatar-mini {
              width: 50px;
              height: 50px;
              border-radius: 50%;
              margin-right: 12px;
              background: white;
              display: flex;
              align-items: center;
              justify-content: center;
              font-size: 24px;
            }

            .chat-name { font-weight: 600; font-size: 14px; }
            .chat-last { opacity: 0.8; font-size: 12px; margin-top: 2px; }

            /* SUGERENCIAS DE CONTACTO */
            .suggestions-scroll {
                display: flex;
                gap: 12px;
                padding: 0 15px 20px 15px;
                overflow-x: auto;

                /* Para Firefox */
                scrollbar-width: none; 

                /* Para Internet Explorer y Edge antiguo */
                -ms-overflow-style: none; 
            }

            /* Para Chrome, Safari y Edge moderno */
            .suggestions-scroll::-webkit-scrollbar {
                display: none;
            }

            .suggestion-card {
                min-width: 140px;
                background: white;
                border-radius: 15px;
                padding: 15px;
                text-align: center;
                color: #333;
            }

            .suggestion-card img {
                width: 80px;      /* Tamaño fijo */
                height: 80px;     /* Tamaño fijo igual al ancho */
                border-radius: 50%; /* Círculo perfecto */
                margin-bottom: 10px;
                object-fit: cover;  /* IMPORTANTE: Esto evita que la imagen se estire */
                border: 2px solid #eee; /* Opcional: un borde para que resalte */
            }

            /*#profileImg {
                width: 100px;
                height: 100px;
                border-radius: 50%;
                object-fit: cover;
                margin-bottom: 15px;
            }*/

            .suggestion-card img {
                width: 65px;
                height: 65px;
                border-radius: 50%;
                margin-bottom: 10px;
                object-fit: cover;
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
            .menu{
                position:absolute;
                bottom:0;
                width:100%;
                height:70px;
                background:rgba(0, 0, 0, 0.504);
                display:flex;
                justify-content:space-around;
                align-items:center;
                font-size:12px;
            }

            .menu div{
                text-align:center;
                cursor:pointer;
                padding:8px 10px;
                border-radius:12px;
                transition:0.2s;
            }

            .menu .active{
                background:rgba(255,255,255,0.25);
                transform:scale(1.05);
                font-weight:bold;
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
            }

            /* ÁREA DE MENSAJES */
            .chat-box {
                flex: 1;
                padding: 20px;
                overflow-y: auto;
                display: flex;
                flex-direction: column;
                gap: 15px;
                background: #fafafc;
            }

            .msg {
                max-width: 75%;
                padding: 12px 18px;
                border-radius: 18px;
                font-size: 13px;
                line-height: 1.5;
                position: relative;
                word-wrap: break-word;
                /* Quitamos cualquier text-shadow heredado de forma general */
                text-shadow: none !important; 
            }

            .msg.user {
                align-self: flex-end;
                background: #4c6ef5;
                color: white;
                border-bottom-right-radius: 4px;
            }

            .msg.bot {
                align-self: flex-start;
                background: white;
                color: #333;
                border-bottom-left-radius: 4px;
                border: 1px solid #eee;
                box-shadow: 0 2px 5px rgba(0,0,0,0.03);
            }

            /* ÁREA DE ENTRADA */
            .chat-input-area {
                padding: 15px;
                display: flex;
                gap: 10px;
                border-top: 1px solid #eee;
                background: white;
            }

            .chat-input-area input {
                flex: 1;
                border: 1px solid #ddd;
                border-radius: 20px;
                padding: 10px 18px;
                outline: none;
                font-size: 13px;
            }

            .chat-input-area button {
                background: #4c6ef5;
                color: white;
                border: none;
                width: 38px;
                height: 38px;
                border-radius: 50%;
                cursor: pointer;
            }

            /* --- CORRECCIÓN DE PUNTITOS (ANIMACIÓN VIVORITA) --- */

            /* --- ESTILOS PARA LA BURBUJA DE CARGA (SIN PUNTOS NEGROS) --- */

            #typing-bubble {
                display: flex;
                align-items: center;
                gap: 5px;
                width: fit-content;
                padding: 12px 18px;
                background: #f1f3f5; /* Color de fondo de la burbuja del bot */
                border-radius: 18px 18px 18px 4px;
                border: 1px solid #eee;
                /* Forzamos que no haya sombras en la burbuja */
                box-shadow: none !important;
                text-shadow: none !important;
            }

            .dot {
                width: 8px;
                height: 8px;
                background-color: #4c6ef5 !important; /* Azul Serena */
                border-radius: 50%;
                display: inline-block;
                /* Eliminamos cualquier borde o sombra del punto */
                border: none !important;
                box-shadow: none !important;
                text-shadow: none !important;

                animation: bounce-serena 1.3s infinite ease-in-out;
            }

            /* Efecto de onda */
            .dot:nth-child(2) { animation-delay: -1.1s; }
            .dot:nth-child(3) { animation-delay: -0.9s; }

            @keyframes bounce-serena {
                0%, 60%, 100% { 
                    transform: translateY(0); 
                    opacity: 0.4; 
                }
                30% { 
                    transform: translateY(-6px); 
                    opacity: 1; 
                }
            }
            
            .chat-last {
                opacity: 0.8;
                font-size: 12px;
                margin-top: 2px;

                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
                max-width: 180px; /* ajusta según tu diseño */
            }
            
            .chat-info {
                flex: 1;
                min-width: 0;
            }
            
            /* --- NUEVOS ESTILOS PARA EL PERFIL (Estilo Imagen) --- */

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
            }

            .profile-info-container {
                width: 90%;
                background: #f4f7f9;
                border-radius: 25px 25px 0 0;
                padding: 20px;
                flex: 1;

                overflow-y: auto;

                /* 🔥 OCULTAR SCROLLBAR */
                scrollbar-width: none;        /* Firefox */
                -ms-overflow-style: none;     /* Edge viejo */
            }

            .profile-info-container::-webkit-scrollbar {
                display: none; /* Chrome, Safari, Edge moderno */
            }

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
                <div class="section-title">En línea ahora</div>
                <div class="online-row">
                    <div class="online-item">
                        <div class="avatar-wrapper">
                            <img src="https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=100" class="avatar-img">
                            <div class="active-dot"></div>
                        </div>
                        <span class="online-name">Dra. López</span>
                    </div>
                    <div class="online-item">
                        <div class="avatar-wrapper">
                            <img src="https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=100" class="avatar-img">
                            <div class="active-dot"></div>
                        </div>
                        <span class="online-name">Dr. Pérez</span>
                    </div>
                    <div class="online-item">
                        <div class="avatar-wrapper">
                            <img src="https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=100" class="avatar-img">
                            <div class="active-dot"></div>
                        </div>
                        <span class="online-name">Dra. Ramírez</span>
                    </div>
                    <div class="online-item">
                        <div class="avatar-wrapper">
                            <img src="https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=100" class="avatar-img">
                            <div class="active-dot"></div>
                        </div>
                        <span class="online-name">Dr. Castillo</span>
                    </div>
                </div>

                <div class="section-title">Mensajes</div>
                <div class="chat-list" id="listaConversaciones">
                    <div class="chat-item" onclick="openChat('Asistente Serena', 'bot')">
                        <div class="chat-avatar-mini">
                            <img src="https://img.icons8.com/color/48/ai-robot--v11.png" alt="Asistente Serena" style="width: 100%; height: 100%;">
                        </div>
                        <div class="chat-info">
                            <div class="chat-name">Asistente Serena</div>
                            <div class="chat-last">¡Hola! ¿Cómo te sientes hoy?</div>   
                        </div>
                    </div>
                    <% 
                        List<ChatLista> misChats = (List<ChatLista>) request.getAttribute("misChats");
                        if (misChats != null) {
                            for (ChatLista chat : misChats) {
                    %>
                    <div class="chat-item" onclick="openChatPsicologo('<%= chat.getNombre().replace("'", "\\'") %>', <%= chat.getIdPsicologo() %>)">
                        <div class="chat-avatar-mini" style="overflow: hidden;">
                            <img src="<%= chat.getFoto() %>" style="width: 100%; height: 100%; object-fit: cover;">
                        </div>
                        <div class="chat-info">
                            <div class="chat-name"><%= chat.getNombre() %></div>
                            <div class="chat-last"><%= chat.getUltimoMensaje() %></div>
                        </div>
                    </div>
                    <% 
                            }
                        } 
                    %>
                </div>

                <!-- 🔹 TARJETAS DINÁMICAS -->
                <div class="section-title">Psicólogos que podrías contactar</div>
                
                <%
                    List<Psicologo> psicologos = (List<Psicologo>) request.getAttribute("listaPsicologos");
                %>

                <div class="suggestions-scroll">
                    <%
                        if (psicologos != null && !psicologos.isEmpty()) {
                            for (Psicologo p : psicologos) {

                                // 1. Definimos el link de respaldo (Placeholder)
                                String urlDefault = "https://img.icons8.com/3d-sugary/100/generic-user.png";

                                // 2. Lógica para decidir si usar Base64 o el Link Externo
                                String fotoData = p.getFoto();
                                String imgSrc;

                                if (fotoData == null || fotoData.trim().isEmpty()) {
                                    imgSrc = urlDefault;
                                } else {
                                    // Si ya es una URL (porque lo configuraste en el Servlet) la dejamos igual, 
                                    // si es solo el texto Base64 le agregamos el prefijo.
                                    imgSrc = p.getFoto();//le quite Strin al inicio
                                }

                                // 3. Limpieza de textos para evitar errores en JavaScript
                                String nombre = p.getNombre() != null ? p.getNombre().replace("'", "\\'") : "Psicólogo";
                                String especialidad = p.getEspecialidad() != null ? p.getEspecialidad().replace("'", "\\'") : "General";
                                String experiencia = p.getExperiencia() != null ? p.getExperiencia().replace("'", "\\'") : "";
                                String cedula = p.getCedula() != null ? p.getCedula().replace("'", "\\'") : "";
                                String modalidad = p.getModalidad() != null ? p.getModalidad().replace("'", "\\'") : "";
                    %>

                    <div class="suggestion-card">
                        <img src="<%= imgSrc %>" alt="Foto de perfil">
                        <span class="suggestion-name"><%= p.getNombre() %></span>
                        <button class="btn-contact" onclick="openChatPsicologo('<%= nombre %>', <%= p.getId() %>)">Contactar</button>
                        <button class="btn-profile" onclick="openProfile('<%= nombre %>','<%= imgSrc %>','<%= especialidad %>','<%= experiencia %>','<%= cedula %>','<%= modalidad %>')">Ver perfil</button>
                    </div>

                    <%
                            }
                        } else {
                    %>

                    <p style="padding: 20px; font-size: 12px; color: white; text-align: center; width: 100%;">No hay psicólogos disponibles en este momento</p>

                    <% } %>
                </div>
            </div>

            <div class="menu">
                    <div onclick="location.href='${pageContext.request.contextPath}/pages/homeTrabajador.jsp';">🏠<br>Inicio</div>
                    <div onclick="location.href='${pageContext.request.contextPath}/pages/sueno.jsp';">🌙<br>Sueño</div>
                    <div onclick="location.href='${pageContext.request.contextPath}/pages/meditar.jsp';">🧘<br>Meditar</div>
                    <div onclick="location.href='${pageContext.request.contextPath}/pages/audios.jsp';">🎵<br>Audios</div>
                    <div class="active" onclick="location.href='${pageContext.request.contextPath}/ListarPsicologosServlet';">💬<br>Chat</div>
                    <div onclick="location.href='${pageContext.request.contextPath}/pages/perfil.jsp';">👤<br>Perfil</div>
            </div>

            <!-- 🔹 MODAL CHAT -->
            <div id="chatModal" class="chat-modal">
                <div class="chat-header">
                    <span id="chatTargetName">Asistente Serena</span>
                    <button onclick="closeChat()" style="background:none; border:none; color:white; font-size:20px;">✕</button>
                </div>

                <div id="chatBox" class="chat-box">
                    <div class="msg bot">¡Hola! ¿En que te puedo ayudar el día de hoy?</div>
                </div>

                <div class="chat-input-area">
                    <input type="text" id="userInput" placeholder="Escribe un mensaje..." onkeypress="handleKeyPress(event)">
                    <button onclick="sendMessage()">➤</button>
                </div>
            </div>

            <!-- 🔹 MODAL PERFIL -->
            <div id="profileModal" class="chat-modal">
            <button class="close-profile-btn" onclick="closeProfile()">✕</button>

            <div class="profile-modal-content">
                <div class="profile-header-custom">
                    <img id="profileImg" src="" alt="Foto de perfil">
                    <h2 id="profileName" style="margin: 0; font-size: 22px;"></h2>
                    <p id="profileRole" style="margin: 5px 0; opacity: 0.8; font-size: 14px;"></p>
                </div>

                <div class="profile-info-container">
                    <span class="info-label">Información profesional</span>

                    <div class="info-card">
                        <strong>Cédula profesional:</strong>
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
        </div>
    </div>
            <script>
                // Variable global para identificar la burbuja de carga
                let typingIndicator = null;
                let idPsicologoActual = null;
                let chats = {}; // guarda conversaciones por usuario

                function openChat(name) {
                    idPsicologoActual = null; // IA

                    document.getElementById('chatTargetName').innerText = name;
                    document.getElementById('chatModal').style.display = 'flex';

                    cargarChat('bot'); // 🔥 ESTA LÍNEA ES LA CLAVE
                }
                
                function openChatPsicologo(nombre, idPsicologo) {
                    idPsicologoActual = idPsicologo; // 👈 aquí sabemos que es chat real

                    document.getElementById('chatTargetName').innerText = nombre;
                    document.getElementById('chatModal').style.display = 'flex';
                    
                    cargarChat(idPsicologo);
                }

                function closeChat() {
                    document.getElementById('chatModal').style.display = 'none';
                }

                function handleKeyPress(e) {
                    if (e.key === 'Enter') sendMessage();
                }

                async function sendMessage() {
                    const input = document.getElementById('userInput');
                    const message = input.value.trim();

                    if (!message || input.disabled) return;

                    // 1. Pintamos el mensaje del usuario de inmediato
                    addMessage(message, 'user');
                    input.value = '';
                    input.disabled = true;

                    // Solo mostramos la animación de "escribiendo" si es la IA
                    if (idPsicologoActual === null) {
                        showTyping();
                    }

                    try {
                        let url = '';
                        let body = '';

                        if (idPsicologoActual === null) {
                            // 🤖 IA
                            url = '<%= request.getContextPath() %>/ListarPsicologosServlet';
                            body = 'mensaje=' + encodeURIComponent(message);
                        } else {
                            // 👩‍⚕️ PSICÓLOGO
                            url = '<%= request.getContextPath() %>/MensajePsicologoSerlvet';
                            body = 'mensaje=' + encodeURIComponent(message) +
                                   '&idPsicologo=' + idPsicologoActual;
                        }

                        const response = await fetch(url, {
                            method: 'POST',
                            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                            body: body
                        });

                        const text = await response.text();

                        if (idPsicologoActual === null) {
                            // 🤖 Para la IA: Quitamos animación y mostramos su respuesta
                            removeTyping();
                            addMessage(text, 'bot');
                        } else {
                            // 👩‍⚕️ Para el Psicólogo: Solo verificamos si hubo error en el Servlet
                            if (text.includes("Error")) {
                                addMessage("Sistema: " + text, 'bot');
                            }
                            // No agregamos 'text' al chat porque el psicólogo no responde en tiempo real
                        }

                    } catch (error) {
                        if (idPsicologoActual === null) removeTyping();
                        addMessage("Error de conexión al servidor", 'bot');
                    } finally {
                        input.disabled = false;
                        input.focus();
                    }
                }

                function addMessage(text, side) {
                    const chatBox = document.getElementById('chatBox');
                    const div = document.createElement('div');
                    div.classList.add('msg', side);
                    div.innerText = text;
                    chatBox.appendChild(div);
                    chatBox.scrollTop = chatBox.scrollHeight;
                    
                    // 🔥 GUARDAR MENSAJE
                    const id = idPsicologoActual || 'bot';

                    if (!chats[id]) {
                        chats[id] = [];
                    }

                    chats[id].push({
                        texto: text,
                        tipo: side
                    });
                }

                function showTyping() {
                    const chatBox = document.getElementById('chatBox');

                    // Crear el contenedor de la burbuja
                    typingIndicator = document.createElement('div');
                    typingIndicator.classList.add('msg', 'bot');
                    typingIndicator.id = 'typing-bubble';

                    // CORRECCIÓN: Quitamos el carácter &#8226; para eliminar los puntos grises
                    typingIndicator.innerHTML = '<span class="dot"></span><span class="dot"></span><span class="dot"></span>'; 

                    chatBox.appendChild(typingIndicator);

                    // Asegurar que el scroll baje
                    chatBox.scrollTop = chatBox.scrollHeight;
                }

                function removeTyping() {
                    if (typingIndicator) {
                        typingIndicator.remove();
                        typingIndicator = null;
                    }
                }

                function openProfile(nombre, foto, especialidad, experiencia, cedula, modalidad) {
                    document.getElementById('profileName').innerText = nombre;
                    document.getElementById('profileImg').src = foto;
                    document.getElementById('profileEsp').innerText = especialidad || "No disponible";
                    document.getElementById('profileExp').innerText = experiencia || "No disponible";
                    document.getElementById('profileLic').innerText = cedula || "No disponible";
                    document.getElementById('profileMod').innerText = modalidad || "No disponible";

                    document.getElementById('profileModal').style.display = 'flex';
                }

                function closeProfile() {
                    document.getElementById('profileModal').style.display = 'none';
                }
                
                setInterval(actualizarChats, 1000); // cada 1 segundo

                async function actualizarChats() {
                    try {
                        const response = await fetch(window.location.href);
                        const html = await response.text();

                        // Crear un DOM temporal
                        const parser = new DOMParser();
                        const doc = parser.parseFromString(html, 'text/html');

                        // Obtener la nueva lista
                        const nuevaLista = doc.getElementById('listaConversaciones');

                        // Reemplazar la actual
                        document.getElementById('listaConversaciones').innerHTML = nuevaLista.innerHTML;

                    } catch (error) {
                        console.error("Error actualizando chats:", error);
                    }
                }
                
                function cargarChat(id) {
                    const chatBox = document.getElementById('chatBox');
                    chatBox.innerHTML = '';

                    if (chats[id] && chats[id].length > 0) {
                        chats[id].forEach(msg => {
                            const div = document.createElement('div');
                            div.classList.add('msg', msg.tipo);
                            div.innerText = msg.texto;
                            chatBox.appendChild(div);
                        });
                    } else {
                        chatBox.innerHTML = '<div class="msg bot">Hola, ¿en qué puedo ayudarte el día de hoy?</div>';
                    }
                }

            </script>

    </body>
</html>