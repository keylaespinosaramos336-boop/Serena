<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

    Integer idPsicologoSession = (Integer) session.getAttribute("idPsicologo");
    if (idPsicologoSession == null) {
        response.sendRedirect("login.html");
        return;
    }
    int idPsicologo = idPsicologoSession;

    String DB_URL  = System.getenv().getOrDefault("DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8");
    String DB_USER = System.getenv().getOrDefault("DB_USER", "root");
    String DB_PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    List<Map<String,String>> conversaciones = new ArrayList<>();
    int totalNoLeidos = 0;

    try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
        String sql =
            "SELECT cp.id_chat, u.id_usuario, u.nombre AS nombre_paciente, u.foto, " +
            "  (SELECT mp.mensaje FROM mensaje_psicologo mp " +
            "   WHERE mp.id_chat = cp.id_chat ORDER BY mp.fecha DESC LIMIT 1) AS ultimo_mensaje, " +
            "  (SELECT mp2.fecha FROM mensaje_psicologo mp2 " +
            "   WHERE mp2.id_chat = cp.id_chat ORDER BY mp2.fecha DESC LIMIT 1) AS ultima_fecha, " +
            "  (SELECT COUNT(*) FROM mensaje_psicologo mp3 " +
            "   WHERE mp3.id_chat = cp.id_chat AND mp3.remitente = 'usuario' AND mp3.leido = 0) AS no_leidos " +
            "FROM chat_psicologo cp " +
            "JOIN usuario u ON u.id_usuario = cp.id_usuario " +
            "WHERE cp.id_psicologo = ? " +
            "ORDER BY ultima_fecha DESC";

        PreparedStatement ps = con.prepareStatement(sql);
        ps.setInt(1, idPsicologo);
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            Map<String,String> chat = new HashMap<>();
            chat.put("idChat",        rs.getString("id_chat"));
            chat.put("idUsuario",     rs.getString("id_usuario"));
            chat.put("nombre",        rs.getString("nombre_paciente"));
            String fotoVal = rs.getString("foto");
            chat.put("foto", (fotoVal != null && !fotoVal.isEmpty())
                                ? fotoVal
                                : "https://img.icons8.com/3d-sugary/100/generic-user.png");
            String ult = rs.getString("ultimo_mensaje");
            chat.put("ultimoMensaje", ult != null ? ult : "Iniciar conversacion");
            chat.put("noLeidos", rs.getString("no_leidos"));
            conversaciones.add(chat);
            totalNoLeidos += rs.getInt("no_leidos");
        }
    } catch (Exception e) { e.printStackTrace(); }

    String ctxPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Chat - Serena</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{
    margin:0;height:100vh;
    display:flex;justify-content:center;align-items:center;
    background:#e6e6e6;font-family:'Plus Jakarta Sans',sans-serif;
}
.phone-frame{
    width:380px;height:760px;background:black;
    border-radius:50px;padding:15px;
    box-shadow:0 30px 60px rgba(0,0,0,0.4);
    display:flex;justify-content:center;align-items:center;
}
.phone{
    width:340px;height:680px;
    background:linear-gradient(180deg,#6aa3d6,#3f6ba9);
    border-radius:40px;overflow:hidden;
    color:white;position:relative;
    display:flex;flex-direction:column;
}
.notch{
    width:120px;height:25px;background:black;
    border-radius:0 0 20px 20px;
    position:absolute;top:0;left:50%;transform:translateX(-50%);z-index:10;
}

/* HEADER */
.header{
    padding:38px 18px 12px;
    display:flex;align-items:center;justify-content:space-between;flex-shrink:0;
}
.header-left h1{font-size:20px;font-weight:800;letter-spacing:-.3px;}
.header-left p{font-size:11px;opacity:.7;margin-top:1px;}
.notif-badge{
    background:white;color:#3f6ba9;
    font-size:11px;font-weight:800;padding:4px 10px;border-radius:20px;
}

/* BUSCADOR */
.search-wrap{padding:0 15px 12px;flex-shrink:0;}
.search-box{
    background:rgba(255,255,255,0.18);border-radius:12px;
    padding:9px 14px;display:flex;align-items:center;gap:8px;
    font-size:12px;opacity:.8;
}

/* SCROLL */
.content{flex:1;overflow-y:auto;padding:0 0 80px;scrollbar-width:none;}
.content::-webkit-scrollbar{display:none;}

.section-title{
    font-size:12px;font-weight:700;opacity:.7;
    text-transform:uppercase;letter-spacing:.5px;margin:12px 15px 8px;
}

/* ITEM */
.chat-item{
    display:flex;align-items:center;
    margin:0 12px 8px;cursor:pointer;
    background:rgba(255,255,255,0.12);
    padding:11px 12px;border-radius:16px;transition:background .2s;gap:11px;
}
.chat-item:hover{background:rgba(255,255,255,0.22);}
.chat-item.unread{background:rgba(255,255,255,0.2);border-left:3px solid rgba(255,255,255,0.6);}
.chat-avatar{
    width:46px;height:46px;border-radius:50%;
    object-fit:cover;flex-shrink:0;
    border:2px solid rgba(255,255,255,0.3);
}
.chat-avatar-ini{
    width:46px;height:46px;border-radius:50%;
    background:rgba(255,255,255,0.25);
    display:flex;align-items:center;justify-content:center;
    font-size:16px;font-weight:800;flex-shrink:0;
}
.chat-info{flex:1;min-width:0;}
.chat-name{font-size:13px;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.chat-last{font-size:11px;opacity:.7;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:170px;}
.unread-dot{
    width:18px;height:18px;border-radius:50%;
    background:white;color:#3f6ba9;
    font-size:9px;font-weight:800;
    display:flex;align-items:center;justify-content:center;flex-shrink:0;
}

/* EMPTY */
.empty{text-align:center;padding:40px 20px;opacity:.6;}
.empty .ei{font-size:40px;margin-bottom:10px;}
.empty p{font-size:12px;}

/* MENÚ */
.menu{
    position:absolute;bottom:0;width:100%;height:65px;
    background:rgba(0,0,0,0.6);
    display:flex;justify-content:space-around;align-items:center;
    font-size:11px;backdrop-filter:blur(5px);
}
.menu div{text-align:center;cursor:pointer;color:rgba(255,255,255,0.7);}
.menu .active{color:white;font-weight:bold;}

/* MODAL CHAT */
.chat-modal{
    display:none;position:absolute;
    top:35px;left:8px;right:8px;bottom:70px;
    background:#f7f9fc;border-radius:24px;
    z-index:100;flex-direction:column;
    box-shadow:0 15px 40px rgba(0,0,0,0.3);
    color:#333;overflow:hidden;
}
.chat-header{
    background:linear-gradient(135deg,#4a7fc1,#3a63a0);
    color:white;padding:12px 14px;
    display:flex;align-items:center;gap:10px;flex-shrink:0;
}
.chat-header-av{
    width:36px;height:36px;border-radius:50%;
    object-fit:cover;border:2px solid rgba(255,255,255,0.4);flex-shrink:0;
}
.chat-header-av-ini{
    width:36px;height:36px;border-radius:50%;
    background:rgba(255,255,255,0.25);
    display:flex;align-items:center;justify-content:center;
    font-size:13px;font-weight:800;flex-shrink:0;
}
.chat-header-info{flex:1;}
.chat-header-name{font-size:14px;font-weight:700;}
.chat-header-sub{font-size:10px;opacity:.75;margin-top:1px;}
.btn-close{background:none;border:none;color:white;font-size:20px;cursor:pointer;padding:2px 6px;}

/* CHAT BOX */
.chat-box{
    flex:1;padding:14px;overflow-y:auto;
    display:flex;flex-direction:column;gap:8px;
    background:#f0f4f8;scrollbar-width:none;
}
.chat-box::-webkit-scrollbar{display:none;}

/* BURBUJAS */
.msg{
    max-width:78%;padding:10px 14px;
    border-radius:18px;font-size:12px;
    line-height:1.5;word-wrap:break-word;
}
.msg.psicologo{
    align-self:flex-end;
    background:linear-gradient(135deg,#4a7fc1,#3a63a0);
    color:white;border-bottom-right-radius:4px;
    box-shadow:0 2px 8px rgba(74,127,193,.35);
}
.msg.usuario{
    align-self:flex-start;
    background:white;color:#333;
    border-bottom-left-radius:4px;
    border:1px solid #e0e8f0;
    box-shadow:0 2px 6px rgba(0,0,0,.05);
}
.msg-time{font-size:9px;opacity:.55;margin-top:3px;display:block;text-align:right;}
.msg.usuario .msg-time{text-align:left;}

/* INPUT */
.chat-input-area{
    padding:10px 12px;display:flex;gap:8px;align-items:center;
    border-top:1px solid #e5ecf3;background:white;flex-shrink:0;
}
.chat-input-area input{
    flex:1;border:1.5px solid #dde3ea;border-radius:20px;
    padding:9px 15px;outline:none;font-size:12px;
    font-family:'Plus Jakarta Sans',sans-serif;transition:border .2s;
}
.chat-input-area input:focus{border-color:#4a7fc1;}
.btn-send{
    background:linear-gradient(135deg,#4a7fc1,#3a63a0);
    color:white;border:none;width:36px;height:36px;
    border-radius:50%;cursor:pointer;font-size:15px;
    display:flex;align-items:center;justify-content:center;flex-shrink:0;
}
.btn-send:hover{opacity:.85;}
.loading-msg{text-align:center;font-size:11px;color:#aaa;padding:20px;}
</style>
</head>
<body>

<div class="phone-frame">
<div class="phone">
<div class="notch"></div>

<!-- HEADER -->
<div class="header">
    <div class="header-left">
        <h1>&#128172; Mensajes</h1>
        <p>Conversaciones con pacientes</p>
    </div>
    <% if (totalNoLeidos > 0) { %>
    <div class="notif-badge">
        <%= totalNoLeidos %> nuevo<%= totalNoLeidos > 1 ? "s" : "" %>
    </div>
    <% } %>
</div>

<!-- BUSCADOR -->
<div class="search-wrap">
    <div class="search-box">&#128269; Buscar paciente...</div>
</div>

<!-- LISTA -->
<div class="content">
    <div class="section-title">Pacientes</div>
    <div id="listaConversaciones">
        <% if (conversaciones.isEmpty()) { %>
        <div class="empty">
            <div class="ei">&#128172;</div>
            <p>Aun no tienes conversaciones.<br>Los pacientes te escribiran aqui.</p>
        </div>
        <% } else {
            for (Map<String,String> conv : conversaciones) {
                String nombre   = conv.get("nombre");
                String ini      = "";
                for (String parte : nombre.split(" "))
                    if (!parte.isEmpty() && ini.length() < 2) ini += parte.charAt(0);
                ini = ini.toUpperCase();
                int noLeidos    = Integer.parseInt(conv.get("noLeidos"));
                boolean unread  = noLeidos > 0;
                String fotoUrl  = conv.get("foto");
                boolean tieneFoto = fotoUrl != null && !fotoUrl.isEmpty()
                    && !fotoUrl.contains("generic-user");
                // Escapar para atributo HTML onclick (comillas simples)
                String nombreJs = nombre.replace("\\","\\\\").replace("'","\\'");
                String fotoJs   = fotoUrl.replace("\\","\\\\").replace("'","\\'");
                String idChat   = conv.get("idChat");
        %>
        <div class="chat-item <%= unread ? "unread" : "" %>"
             onclick="abrirChat('<%= idChat %>','<%= nombreJs %>','<%= fotoJs %>','<%= ini %>')">

            <% if (tieneFoto) { %>
            <img src="<%= fotoUrl %>" class="chat-avatar" alt="">
            <% } else { %>
            <div class="chat-avatar-ini"><%= ini %></div>
            <% } %>

            <div class="chat-info">
                <div class="chat-name"><%= nombre %></div>
                <div class="chat-last"><%= conv.get("ultimoMensaje") %></div>
            </div>

            <% if (unread) { %>
            <div class="unread-dot"><%= noLeidos %></div>
            <% } %>
        </div>
        <% } } %>
    </div>
</div>

<!-- MENÚ -->
<div class="menu">
    <div onclick="location.href='homePsicologo.jsp'">&#127968;<br>Home</div>
    <div class="active">&#128172;<br>Chat</div>
    <div onclick="location.href='reportes.jsp'">&#128202;<br>Reportes</div>
    <div onclick="location.href='perfilPsicologo.jsp'">&#128100;<br>Perfil</div>
</div>

<!-- MODAL CHAT -->
<div id="chatModal" class="chat-modal">

    <div class="chat-header">
        <div id="chatAv" class="chat-header-av-ini">?</div>
        <div class="chat-header-info">
            <div class="chat-header-name" id="chatNombre">Paciente</div>
            <div class="chat-header-sub">Paciente</div>
        </div>
        <button class="btn-close" onclick="cerrarChat()">&#10005;</button>
    </div>

    <div id="chatBox" class="chat-box">
        <div class="loading-msg">Selecciona una conversacion para comenzar</div>
    </div>

    <div class="chat-input-area">
        <input type="text" id="msgInput"
               placeholder="Escribe tu respuesta..."
               onkeypress="if(event.key==='Enter') enviarMensaje()">
        <button class="btn-send" onclick="enviarMensaje()">&#10148;</button>
    </div>
</div>

</div><!-- /phone -->
</div><!-- /phone-frame -->

<script>
// Ruta del servlet (sin backticks para evitar error EL del JSP)
var SERVLET_URL = '<%= ctxPath %>/ChatPsicologoServlet';

var idChatActual    = null;
var pollingInterval = null;
var ultimoIdMsg     = 0;

/* Abrir el modal de chat */
function abrirChat(idChat, nombre, foto, ini) {
    idChatActual = idChat;
    ultimoIdMsg  = 0;

    // Actualizar nombre
    document.getElementById('chatNombre').textContent = nombre;

    // Actualizar avatar
    var avEl = document.getElementById('chatAv');
    var tieneFoto = foto && foto.indexOf('generic-user') === -1 && foto.length > 10;
    if (tieneFoto) {
        var img       = document.createElement('img');
        img.src       = foto;
        img.className = 'chat-header-av';
        img.id        = 'chatAv';
        avEl.parentNode.replaceChild(img, avEl);
    } else {
        avEl.className   = 'chat-header-av-ini';
        avEl.id          = 'chatAv';
        avEl.textContent = ini;
    }

    // Mostrar modal y limpiar
    document.getElementById('chatModal').style.display = 'flex';
    document.getElementById('chatBox').innerHTML =
        '<div class="loading-msg">Cargando mensajes...</div>';

    // Cargar historial + marcar leido
    cargarMensajes(true);
    marcarLeido(idChat);

    // Polling cada 3s
    if (pollingInterval) clearInterval(pollingInterval);
    pollingInterval = setInterval(function() { cargarMensajes(false); }, 3000);
}

/* Cerrar modal */
function cerrarChat() {
    document.getElementById('chatModal').style.display = 'none';
    if (pollingInterval) { clearInterval(pollingInterval); pollingInterval = null; }
    idChatActual = null;
    actualizarLista();
}

/* GET mensajes */
function cargarMensajes(completo) {
    if (!idChatActual) return;
    var desde = completo ? 0 : ultimoIdMsg;
    var url   = SERVLET_URL + '?accion=getMensajes&idChat=' + idChatActual + '&desde=' + desde;
    var xhr   = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.onload = function() {
        if (xhr.status !== 200) return;
        var data;
        try { data = JSON.parse(xhr.responseText); } catch(e) { return; }

        var box = document.getElementById('chatBox');
        if (completo) {
            box.innerHTML = '';
            if (data.length === 0) {
                box.innerHTML = '<div class="loading-msg" style="color:#bbb;">Sin mensajes aun. Comienza la conversacion.</div>';
                return;
            }
        }
        var nuevos = false;
        for (var i = 0; i < data.length; i++) {
            var msg = data[i];
            if (msg.id > ultimoIdMsg) {
                ultimoIdMsg = msg.id;
                agregarBurbuja(msg.remitente, msg.mensaje, msg.hora);
                nuevos = true;
            }
        }
        if (nuevos || completo) box.scrollTop = box.scrollHeight;
    };
    xhr.send();
}

/* Crear burbuja de mensaje */
function agregarBurbuja(remitente, texto, hora) {
    var box  = document.getElementById('chatBox');
    var div  = document.createElement('div');
    div.className = 'msg ' + (remitente === 'psicologo' ? 'psicologo' : 'usuario');

    // Texto (seguro: textContent primero, luego appendChild del span)
    var textoNodo = document.createTextNode(texto);
    div.appendChild(textoNodo);

    var span = document.createElement('span');
    span.className   = 'msg-time';
    span.textContent = hora;
    div.appendChild(span);

    box.appendChild(div);
}

/* POST enviar mensaje */
function enviarMensaje() {
    var input   = document.getElementById('msgInput');
    var mensaje = input.value.trim();
    if (!mensaje || !idChatActual) return;

    input.value    = '';
    input.disabled = true;

    // Burbuja optimista inmediata
    agregarBurbuja('psicologo', mensaje, horaActual());
    document.getElementById('chatBox').scrollTop = 99999;

    var xhr  = new XMLHttpRequest();
    var body = 'accion=enviar&idChat=' + encodeURIComponent(idChatActual) +
               '&mensaje=' + encodeURIComponent(mensaje);
    xhr.open('POST', SERVLET_URL, true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.onload = function() {
        if (xhr.responseText && xhr.responseText.indexOf('Error') === 0) {
            agregarBurbuja('usuario', 'Sistema: ' + xhr.responseText, horaActual());
        }
        input.disabled = false;
        input.focus();
        actualizarLista();
    };
    xhr.onerror = function() {
        agregarBurbuja('usuario', 'Error de conexion', horaActual());
        input.disabled = false;
    };
    xhr.send(body);
}

/* POST marcar leido */
function marcarLeido(idChat) {
    var xhr  = new XMLHttpRequest();
    var body = 'accion=marcarLeido&idChat=' + encodeURIComponent(idChat);
    xhr.open('POST', SERVLET_URL, true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.send(body);
}

/* Refrescar lista de conversaciones */
function actualizarLista() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', window.location.href, true);
    xhr.onload = function() {
        if (xhr.status !== 200) return;
        var doc = new DOMParser().parseFromString(xhr.responseText, 'text/html');
        var nueva = doc.getElementById('listaConversaciones');
        if (nueva) document.getElementById('listaConversaciones').innerHTML = nueva.innerHTML;
    };
    xhr.send();
}

/* Hora local HH:mm */
function horaActual() {
    var d = new Date();
    return ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2);
}

// Refrescar lista cada 5s para ver mensajes nuevos aunque el modal esté cerrado
setInterval(actualizarLista, 5000);
</script>

</body>
</html>
