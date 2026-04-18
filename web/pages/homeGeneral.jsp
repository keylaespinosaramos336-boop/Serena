<%-- BLOQUE QUE SE AGREGA PARA RECUPERAR EL NOMBRE DEL LOGINSERVLET --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String nombreCompleto = (String) session.getAttribute("nombreUsuario");
    String primerNombre = "Usuario"; 

    if (nombreCompleto != null && !nombreCompleto.trim().isEmpty()) {
        int espacio = nombreCompleto.trim().indexOf(" ");
        if (espacio != -1) {
            primerNombre = nombreCompleto.trim().substring(0, espacio);
        } else {
            primerNombre = nombreCompleto.trim();
        }
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
background:url('https://i.postimg.cc/W4SJmtNL/home.jpg') center/cover;
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

.content{
flex:1;
background:rgba(0,0,0,0.25);
border-radius:30px 30px 0 0;
padding:20px;
overflow-y:auto;
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

.card-featured{
background:white;
color:#333;
border-radius:18px;
padding:12px;
display:flex;
align-items:center;
gap:12px;
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

.card-play{
font-size:12px;
color:#4c6ef5;
font-weight:700;
cursor:pointer;
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
<div class="mood-btn">😢</div>
<div class="mood-btn">😕</div>
<div class="mood-btn">😊</div>
<div class="mood-btn">😁</div>
<div class="mood-btn">😌</div>
</div>

<div class="section-title">Accesos rápidos</div>

<div class="quick-nav">

<div class="circle-item">
<div class="circle">🎧</div>
<span>Audios</span>
</div>

<div class="circle-item">
<div class="circle">🧘</div>
<span>Pausas</span>
</div>

<div class="circle-item">
<div class="circle">💡</div>
<span>Consejos</span>
</div>

<div class="circle-item">
<div class="circle">📈</div>
<span>Progreso</span>
</div>

</div>

<div class="section-title">Tu progreso hoy</div>

<div class="card-featured">

<img src="https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=150&q=80" class="card-img">

<div class="card-info">
<h4>Pausa de Respiración</h4>
<p>Objetivo de hoy: 5 min</p>
<div class="card-play">? Continuar sesión</div>
</div>

</div>

</div>

<div class="menu">

<div class="active">🏠<br>Inicio</div>

<div>🌙<br>Sueño</div>

<div>🧘<br>Meditar</div>

<div>🎧<br>Audios</div>

<div>💬<br>Chat</div>
<div>👤<br>Perfil</div>

</div>

</div>

</div>

</body>
</html>