<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Sueño - Serena</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">

<style>

body{
margin:0;
height:100vh;
display:flex;
justify-content:center;
align-items:center;
background:#e6e6e6;
font-family:Arial;
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
z-index: 110;
}

/* HEADER */

.header{
padding:40px 25px 25px 25px;
text-align:center;
font-size:22px;
font-weight:bold;
}

/* CONTENEDOR */
.container {
    background: rgba(0,0,0,0.25);
    border-radius: 30px 30px 0 0;
    padding: 20px;
    height: 500px;
    overflow-y: auto;
    
    /* Ocultar scrollbar para Chrome, Safari y Opera */
    -webkit-overflow-scrolling: touch; /* Mejora el scroll en móviles */
}

/* Regla para Chrome, Safari y nuevas versiones de Edge */
.container::-webkit-scrollbar {
    display: none;
}

/* Regla para Firefox */
.container {
    scrollbar-width: none;
}

/* Regla para Internet Explorer y Edge antiguo */
.container {
    -ms-overflow-style: none;
}

/* GRID */

.grid{
display:grid;
grid-template-columns:1fr 1fr;
gap:15px;
}

/* TARJETAS */

.card{
height:140px;
border-radius:18px;
background-size:cover;
background-position:center;
display:flex;
align-items:flex-end;
padding:10px;
font-weight:bold;
cursor:pointer;
transition:0.2s;
}

.card:hover{
transform:scale(1.05);
}

/* TEXTO SOBRE IMAGEN */

.card span{
background:rgba(0,0,0,0.5);
padding:5px 8px;
border-radius:8px;
font-size:13px;
}

/* --- ESTILOS DEL REPRODUCTOR TIPO SPOTIFY --- */
#spotify-player {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(180deg, #2c3e50, #000000);
    z-index: 100;
    display: none; /* Oculto por defecto */
    flex-direction: column;
    align-items: center;
    padding-top: 20px;
    transition: 0.5s ease-in-out;
    justify-content:center;
}

.close-btn {
    position: absolute;
    top: 45px;
    left: 25px;
    font-size: 24px;
    cursor: pointer;
    color: white;
    opacity: 0.8;
    z-index: 102;
}

/* Contenedor del contenido del reproductor (Imagen + Texto + Controles) */
.player-content-block {
    display: flex; flex-direction: column; align-items: center; 
    width: 100%; 
    padding-top: 20px; /* Pequeño ajuste para no pegar con la X */
}

.player-img {
    width: 260px;
    height: 260px;
    border-radius: 20px;
    object-fit: cover;
    box-shadow: 0 15px 35px rgba(0,0,0,0.5);
}

.player-info {
    text-align: left;
    width: 260px;
    margin-top: 35px;
}

.player-info h2 { margin: 0; font-size: 20px; font-weight: 700;}
.player-info p { margin: 5px 0 0; opacity: 0.7; font-size: 14px; }

.progress-container {
    width: 260px;
    height: 4px;
    background: rgba(255,255,255,0.2);
    margin-top: 30px;
    border-radius: 2px;
    cursor:pointer;
}

.progress-bar {
    width: 0%; /* Simulación de progreso */
    height: 100%;
    background: white;
    border-radius: 2px;
    transition: width 0.1s linear;
}

.player-controls {
    display: flex;
    gap: 35px;
    align-items: center;
    margin-top: 40px;
    font-size: 24px;
    color:white;
}

.control-btn { cursor: pointer; opacity: 0.8; transition: 0.2s; }
.control-btn:hover { opacity: 1; transform: scale(1.1); }

.play-btn {
    font-size: 45px;
    /*cursor: pointer;*/
}

/* MENU */

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
z-index: 50;
}

.menu div{
text-align:center;
cursor:pointer;
padding:8px 10px;
border-radius:12px;
transition:0.2s;
color: white; 
text-decoration: none;
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

<div class="notch" id="phone-notch"></div>

<div id="spotify-player">
    <div class="close-btn" onclick="closePlayer()">✕</div>
    <div class="player-content-block">
    <img id="p-img" src="" class="player-img">
    <div class="player-info">
        <h2 id="p-title">Título</h2>
        <p>Concentración Serena</p>
    </div>
    
    <div class="progress-container" id="progress-container">
        <div class="progress-bar" id="progress-bar"></div>
    </div>
    
    <div class="player-controls">
        <span class="control-btn" onclick="prevTrack()">⏮</span>
        <span class="control-btn play-btn" id="play-pause-btn" onclick="togglePlay()">⏸</span>
        <span class="control-btn" onclick="nextTrack()">⏭</span>
    </div>
</div>
    
    <audio id="main-audio" src=""></audio>
</div>

<div class="header">
Tu espacio de sintonía
</div>

<div class="container">

<div class="grid">

<div class="card" id="card-0" onclick="openPlayer(0)" style="background-image:url('https://images.unsplash.com/photo-1758876201566-990fd4e0f3c5?q=80&w=1332&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Binaural beats</span>
</div>

<div class="card" id="card-1" onclick="openPlayer(1)" style="background-image:url('https://plus.unsplash.com/premium_photo-1689177357589-fb06fc00da07?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Sonido marrón</span>
</div>

<div class="card" id="card-2" onclick="openPlayer(2)" style="background-image:url('https://plus.unsplash.com/premium_photo-1683121598398-7293901ce62a?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Lo-Fi Hip Hop</span>
</div>

<div class="card" id="card-3" onclick="openPlayer(3)" style="background-image:url('https://images.unsplash.com/photo-1562815240-be666d2600ce?q=80&w=1234&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Cafetería ambiental</span>
</div>

<div class="card" id="card-4" onclick="openPlayer(4)" style="background-image:url('https://plus.unsplash.com/premium_photo-1723914096379-1cb4de74617c?q=80&w=896&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Afirmaciones de empoderamiento</span>
</div>

<div class="card" id="card-5" onclick="openPlayer(5)" style="background-image:url('https://plus.unsplash.com/premium_photo-1682090682368-dfee64657261?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Música de videojuegos</span>
</div>

</div>

</div>

<div class="menu">

<div onclick="location.href='homeTrabajador.jsp';">🏠<br>Inicio</div>
<div onclick="location.href='sueno.jsp';">🌙<br>Sueño</div>
<div onclick="location.href='meditar.jsp';">🧘<br>Meditar</div>
<div class="active">🎵<br>Audios</div>
<div onclick="location.href='${pageContext.request.contextPath}/ListarPsicologosServlet';">💬<br>Chat</div>
<div onclick="location.href='perfil.jsp';">👤<br>Perfil</div>

</div>

</div>

</div>
    
<%-- 3. PARTE DE LÓGICA DE REPRODUCCIÓN (JAVASCRIPT) --%>
<script>
// 1. Lista de reproducción (Verifica que las rutas de audio sean correctas)
const playlist = [
    { title: 'Concentración profunda', img: 'https://images.unsplash.com/photo-1758876201566-990fd4e0f3c5?q=80&w=1332&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', src: 'https://ia601007.us.archive.org/19/items/super-concentracion/super-concentracion.mp3' },
    { title: 'Ansiedad o TDAH', img: 'https://plus.unsplash.com/premium_photo-1689177357589-fb06fc00da07?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', src: 'https://ia902902.us.archive.org/4/items/ruido-marron/ruido-marron.mp3' },
    { title: 'Trabajo dinámico', img: 'https://plus.unsplash.com/premium_photo-1683121598398-7293901ce62a?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', src: 'https://ia800808.us.archive.org/17/items/hiphop_202604/hiphop.mp3' },
    { title: 'Un extra de cratividad', img: 'https://images.unsplash.com/photo-1562815240-be666d2600ce?q=80&w=1234&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', src: 'https://ia601406.us.archive.org/11/items/ambiente-cafe/ambiente-cafe.mp3' },
    { title: 'Positivismo y confianza', img: 'https://plus.unsplash.com/premium_photo-1723914096379-1cb4de74617c?q=80&w=896&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', src: 'https://ia903101.us.archive.org/19/items/afirmaciones-trabajo/afirmaciones-trabajo.mp3' },
    { title: 'Estimulante en segundo plano', img: 'https://plus.unsplash.com/premium_photo-1682090682368-dfee64657261?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', src: 'https://ia601400.us.archive.org/27/items/videojuegos_202604/videojuegos.mp3' }
];

let currentTrackIndex = 0;
const audio = document.getElementById('main-audio');
const player = document.getElementById('spotify-player');
const playPauseBtn = document.getElementById('play-pause-btn');
const progressBar = document.getElementById('progress-bar');
const notch = document.getElementById('phone-notch');

// Carga los datos en el reproductor
function loadTrack(index) {
    currentTrackIndex = index;
    const track = playlist[index];
    if(track) {
        document.getElementById('p-title').innerText = track.title;
        document.getElementById('p-img').src = track.img;
        audio.src = track.src;
        progressBar.style.width = '0%';
    }
}

// Abre el reproductor
function openPlayer(index) {
    console.log("Abriendo reproductor para el indice:", index);
    loadTrack(index);
    player.style.display = 'flex';
    if(notch) notch.style.background = 'transparent';
    audio.play().catch(e => console.log("Error al reproducir:", e));
    playPauseBtn.innerText = '⏸';
}

// Guarda progreso en la base de datos
function guardarProgresoEnBD() {
    const tiempoActual = Math.floor(audio.currentTime);
    if (tiempoActual > 5) { 
        const minutos = Math.floor(tiempoActual / 60);
        const segundos = tiempoActual % 60;
        const tiempoFormateado = minutos + ":" + (segundos < 10 ? '0' : '') + segundos + " min";
        
        const titulo = document.getElementById('p-title').innerText;
        const imagen = document.getElementById('p-img').src; 

        const params = new URLSearchParams();
        params.append('titulo', titulo);
        params.append('imagen', imagen);
        params.append('tiempo', tiempoFormateado);

        fetch('../GuardarProgresoServlet', {
            method: 'POST',
            body: params
        }).then(() => console.log("Progreso guardado"))
          .catch(err => console.error("Error Fetch:", err));
    }
}

// Cierra el reproductor
function closePlayer() {
    guardarProgresoEnBD();
    player.style.display = 'none';
    if(notch) notch.style.background = 'black';
    audio.pause();
}

function togglePlay() {
    if (audio.paused) {
        audio.play();
        playPauseBtn.innerText = '⏸';
    } else {
        audio.pause();
        playPauseBtn.innerText = '▶︎';
    }
}

function nextTrack() {
    currentTrackIndex = (currentTrackIndex + 1) % playlist.length;
    loadTrack(currentTrackIndex);
    audio.play();
    playPauseBtn.innerText = '⏸';
}

function prevTrack() {
    currentTrackIndex = (currentTrackIndex - 1 + playlist.length) % playlist.length;
    loadTrack(currentTrackIndex);
    audio.play();
    playPauseBtn.innerText = '⏸';
}

// Actualización automática
audio.addEventListener('timeupdate', () => {
    if (audio.duration > 0) {
        let progressWidth = (audio.currentTime / audio.duration) * 100;
        progressBar.style.width = progressWidth + "%";
    }
});

audio.addEventListener('ended', nextTrack);

// Click en barra de progreso
const progContainer = document.getElementById('progress-container');
if(progContainer) {
    progContainer.addEventListener('click', function(e) {
        const width = this.clientWidth;
        const clickX = e.offsetX;
        audio.currentTime = (clickX / width) * audio.duration;
    });
}

window.onload = function() {
    const urlParams = new URLSearchParams(window.location.search);
    const tituloURL = urlParams.get('titulo');
    const tiempoURL = urlParams.get('tiempo');

    if (tituloURL && tiempoURL) {
        // 1. Buscar el índice del audio en tu lista 'playlist'
        const index = playlist.findIndex(t => t.title === tituloURL);
        
        if (index !== -1) {
            // 2. Abrir el reproductor con ese audio
            openPlayer(index);
            
            // 3. Convertir "min:seg min" a segundos puros
            // Ejemplo: "6:59 min" -> 419 segundos
            const partes = tiempoURL.replace(' min', '').split(':');
            const segundosTotales = (parseInt(partes[0]) * 60) + parseInt(partes[1]);
            
            // 4. Saltar a ese segundo
            audio.currentTime = segundosTotales;
        }
    }
};

</script>

</body>
</html>