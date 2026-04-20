<%-- BLOQUE QUE SE AGREGA PARA RECUPERAR EL NOMBRE DEL LOGINSERVLET --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*"%>
<%
    // 1. Verificación de sesión
    Integer idUsuario = (Integer) session.getAttribute("idUsuario");
    if (idUsuario == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // 2. Lógica del nombre de usuario
    String nombreCompleto = (String) session.getAttribute("nombreUsuario");
    String primerNombre = (nombreCompleto != null && !nombreCompleto.trim().isEmpty()) 
                          ? nombreCompleto.trim().split(" ")[0] : "Usuario";

    // 3. Estructura para guardar datos de progreso (Carga antes, dibuja después)
    List<Map<String, String>> listaProgreso = new ArrayList<>();

    // Variables de entorno para Railway (si no están, usa local por defecto)
    String URL = System.getenv().getOrDefault("DB_URL", "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC");
    String USER = System.getenv().getOrDefault("DB_USER", "root");
    String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(URL, USER, PASS);
        
        String sqlProgreso = "SELECT titulo_contenido, imagen_url, tiempo_reproducido FROM progreso_reproduccion " +
                             "WHERE id_usuario = ? AND fecha = CURDATE() ORDER BY id_progreso DESC";
        
        ps = con.prepareStatement(sqlProgreso);
        ps.setInt(1, idUsuario);
        rs = ps.executeQuery();
        
        while (rs.next()) {
            Map<String, String> item = new HashMap<>();
            item.put("titulo", rs.getString("titulo_contenido"));
            item.put("imagen", rs.getString("imagen_url"));
            item.put("tiempo", rs.getString("tiempo_reproducido"));
            listaProgreso.add(item);
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        // Cierre inmediato de recursos: vital para que Railway no te bloquee
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (ps != null) try { ps.close(); } catch (SQLException e) {}
        if (con != null) try { con.close(); } catch (SQLException e) {}
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Inicio - Serena</title>

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

/* MARCO DEL TELEFONO */

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

/* NOTCH */

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

/* HEADER CON IMAGEN */

.header-bg{
height:200px;
background:url('https://images.unsplash.com/photo-1704466211402-d6a869c55a29?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D') center/cover;
position:relative;
display:flex;
flex-direction:column;
justify-content:flex-end;
padding:20px;
}

.header-bg::before{
content:'';
position:absolute;
inset:0;
background:linear-gradient(0deg,rgba(0,0,0,0.4),transparent);
}

.greeting{
position:relative;
z-index:1;
}

.greeting h1{
margin:0;
font-size:18px;
font-weight:700;
}

.greeting p{
margin:5px 0 0;
font-size:13px;
opacity:0.9;
}

/* CONTENIDO */
.content {
    flex: 1;
    background: rgba(0,0,0,0.25);
    border-radius: 30px 30px 0 0;
    padding: 20px;
    padding-bottom: 100px; /* Espacio extra para que la última tarjeta suba */
    overflow-y: auto;
    
    /* OCULTAR SCROLLBAR */
    scrollbar-width: none; /* Firefox */
    -ms-overflow-style: none; /* IE/Edge */
}

/* Ocultar scrollbar para Chrome/Safari */
.content::-webkit-scrollbar {
    display: none;
}

/* TITULO SECCION */

.section-title{
font-size:15px;
font-weight:700;
margin-bottom:12px;
}

/* ESTADO EMOCIONAL */

.mood-bar{
display:flex;
justify-content:space-between;
margin-bottom:25px;
}

.mood-btn{
font-size:20px;
background:rgba(255,255,255,0.2);
width:45px;
height:45px;
display:flex;
align-items:center;
justify-content:center;
border-radius:12px;
cursor:pointer;
transition:0.2s;
}

.mood-btn:hover{
background:rgba(255,255,255,0.35);
transform:scale(1.1);
}

/* ACCESOS RAPIDOS (SIN SCROLL) */

.quick-nav{
display:flex;
justify-content:space-between;
margin-bottom:25px;
}

.circle-item{
width:60px;
text-align:center;
}

.circle{
width:50px;
height:50px;
background:rgba(255,255,255,0.2);
border-radius:50%;
display:flex;
align-items:center;
justify-content:center;
font-size:18px;
margin:0 auto 6px;
transition:0.2s;
cursor:pointer;
}

.circle:hover{
background:rgba(255,255,255,0.35);
transform:scale(1.05);
}

.circle-item span{
font-size:11px;
}

/* TARJETA */

.card-featured {
    background: white;
    color: #333;
    border-radius: 18px;
    padding: 12px;
    display: flex;
    align-items: center;
    gap: 12px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.1); /* Un poco de sombra para resaltar */
}

.card-img{
width:70px;
height:70px;
border-radius:14px;
object-fit:cover;
}

.card-info h4{
margin:0;
font-size:14px;
}

.card-info p{
margin:4px 0;
font-size:12px;
color:#666;
}

.card-play {
    font-size: 12px;
    color: #4c6ef5;
    font-weight: 700;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 4px;
}

/* MENU INFERIOR */

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

/* BOTON ACTIVO */

.menu .active{
background:rgba(255,255,255,0.25);
box-shadow:rgb(76, 110, 245);
transform:scale(1.05);
font-weight:bold;
}

html {
    scroll-behavior: smooth;
}

#lista-progreso {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

</style>
</head>

<body>

<div class="phone-frame">

<div class="phone">

<div class="notch"></div>

<div class="header-bg">
<div class="greeting">
<%-- AQUÍ SE AGREGA LA VARIABLE CON EL NOMBRE --%>
<h1>Buenos días, <%= primerNombre %></h1>
<p>"Hoy es un buen día para cuidar tu bienestar."</p>
</div>
</div>

<div class="content">

<div class="section-title">¿Cómo te sientes?</div>

<div class="mood-bar">
<div class="mood-btn" onclick="registrarAnimo(0)">😢</div>
<div class="mood-btn" onclick="registrarAnimo(25)">😕</div>
<div class="mood-btn" onclick="registrarAnimo(50)">😊</div>
<div class="mood-btn" onclick="registrarAnimo(75)">😁</div>
<div class="mood-btn" onclick="registrarAnimo(100)">😌</div>
</div>

<div class="section-title">Accesos rápidos</div>
<div class="quick-nav">
    <div class="circle-item" onclick="location.href='audios.jsp'">
        <div class="circle">🎧</div>
        <span>Audios</span>
    </div>

    <div class="circle-item" onclick="location.href='meditar.jsp'">
        <div class="circle">🧘</div>
        <span>Pausas</span>
    </div>

    <div class="circle-item" onclick="location.href='perfil.jsp#seccionNiveles'">
        <div class="circle">💡</div>
        <span>Consejos</span>
    </div>

    <div class="circle-item" onclick="location.href='perfil.jsp#seccionGrafica'">
        <div class="circle">📈</div>
        <span>Progreso</span>
    </div> </div>

<div class="section-title">Tu progreso hoy</div>

<div id="lista-progreso">
                    <% if (listaProgreso.isEmpty()) { %>
                        <div style="text-align:center; padding: 20px; opacity: 0.6; font-size: 13px;">
                            <p>Aún no has escuchado nada hoy.<br>¡Comienza una sesión ahora!</p>
                        </div>
                    <% } else {
                        for (Map<String, String> item : listaProgreso) { %>
                            <div class="card-featured">
                                <img src="<%= item.get("imagen") %>" class="card-img" onerror="this.src='https://via.placeholder.com/150?text=Audio'">
                                <div class="card-info">
                                    <h4><%= item.get("titulo") %></h4>
                                    <p>Progreso: <%= item.get("tiempo") %></p>
                                    <div class="card-play" onclick="continuarSesion('<%= item.get("titulo") %>', '<%= item.get("tiempo") %>')">
                                        ▶ Continuar sesión
                                    </div>
                                </div>
                            </div>
                    <% } } %>
                </div>



</div>
<div class="menu">

<div class="active">🏠<br>Inicio</div>
<div onclick="location.href='sueno.jsp';">🌙<br>Sueño</div>
<div onclick="location.href='meditar.jsp';">🧘<br>Meditar</div>
<div onclick="location.href='audios.jsp';">🎧<br>Audios</div>
<div onclick="location.href='${pageContext.request.contextPath}/ListarPsicologosServlet';">💬<br>Chat</div>
<div onclick="location.href='perfil.jsp';">👤<br>Perfil</div>


</div>
</div>

<script>
function registrarAnimo(valor) {
    fetch('../RegistroAnimoServlet', { 
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'valor=' + valor 
    })
    .then(res => res.text())
    .then(data => { if(data.trim() === "success") alert("¡Guardado!"); else alert("Error: " + data); })
    .catch(err => alert("Error de conexión"));
}

function continuarSesion(titulo, tiempo) {
    let destino = "audios.jsp"; // Por defecto
    // Convertimos a minúsculas para comparar fácilmente
    const t = titulo.toLowerCase();
    // Lógica de detección por palabras clave
    if (t.includes("olas") || t.includes("lluvia") || t.includes("dormir") || t.includes("bosque") || t.includes("relajante") || t.includes("afirmaciones")) {
        destino = "sueno.jsp";
    } else if (t.includes("estiramiento") || t.includes("respiración") || t.includes("visual") || t.includes("relajación") || t.includes("meditación") || t.includes("movilidad")) {
        destino = "meditar.jsp";
    }
    console.log("Redirigiendo a: " + destino + " con el título: " + titulo);
    // Redirigimos pasando los parámetros
    window.location.href = destino + "?titulo=" + encodeURIComponent(titulo) + "&tiempo=" + tiempo;
}

</script>

</body>
</html>