<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Meditación - Serena</title>
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

/* PANTALLA DEL TELEFONO */

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

/* header */

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

/* grid */

.grid{
display:grid;
grid-template-columns:1fr 1fr;
gap:15px;
}

/* tarjetas */

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

/* texto sobre imagen */

.card span{
background:rgba(0,0,0,0.5);
padding:5px 8px;
border-radius:8px;
font-size:13px;
}

/* REPRODUCTOR DE VIDEO */
#video-player {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: black;
    z-index: 100;
    display: none; /* Oculto por defecto */
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

.player-video-element {
    width: 280px;
    height: 280px;
    border-radius: 20px;
    object-fit: cover; /* Esto hace que el video llene el cuadrado sin deformarse */
    box-shadow: 0 15px 35px rgba(0,0,0,0.5);
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

<div id="video-player">
    <div class="close-btn" onclick="closePlayer()">✕</div>
    
    <div class="player-content-block">
        <video id="main-video" class="player-video-element" playsinline>
            <source src="" type="video/mp4">
        </video>

        <div class="player-info">
            <h2 id="p-title">Título Meditación</h2>
            <p>Guía Visual Serena</p>
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
    
</div>

<div class="header">
Pausas activas
</div>

<div class="container">

<div class="grid">

<div class="card" onclick="openPlayer(0)" style="background-image:url('https://plus.unsplash.com/premium_photo-1661438486473-78494571fbeb?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Estiramiento en silla</span>
</div>

<div class="card" onclick="openPlayer(1)" style="background-image:url('https://images.unsplash.com/photo-1713428856048-d52b6474b5f7?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Respiración cuadrada</span>
</div>

<div class="card" onclick="openPlayer(2)" style="background-image:url('https://plus.unsplash.com/premium_photo-1661304634388-28a1f48892ab?q=80&w=1169&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Descanso visual</span>
</div>

<div class="card" onclick="openPlayer(3)" style="background-image:url('https://plus.unsplash.com/premium_photo-1682094607329-ee8bb3968762?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Relajación muscular</span>
</div>

<div class="card" onclick="openPlayer(4)" style="background-image:url('https://images.unsplash.com/photo-1506126613408-eca07ce68773');">
<span>Meditación de gratitud</span>
</div>

<div class="card" onclick="openPlayer(5)" style="background-image:url('https://plus.unsplash.com/premium_photo-1679164458634-163862c284bd?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');">
<span>Movilidad de muñecas y manos</span>
</div>

</div>

</div>

<div class="menu">
<div onclick="location.href='homeTrabajador.jsp';">🏠<br>Inicio</div>
<div onclick="location.href='sueno.jsp';">🌙<br>Sueño</div>
<div class="active">🧘<br>Meditar</div>
<div onclick="location.href='audios.jsp';">🎵<br>Audios</div>
<div onclick="location.href='${pageContext.request.contextPath}/ListarPsicologosServlet';">💬<br>Chat</div>
<div onclick="location.href='perfil.jsp';">👤<br>Perfil</div>
</div>

</div>

</div>
    
<script>
// Lista de reproducción con títulos y rutas de video
const playlist = [
    { title: 'Estiramientos en silla', src: 'https://ia902907.us.archive.org/9/items/estiramiento-silla/estiramiento-silla.mp4', img: 'https://plus.unsplash.com/premium_photo-1661438486473-78494571fbeb?q=80&w=1170&auto=format&fit=crop' },
    { title: 'Respiración cuadrada', src: 'https://ia903206.us.archive.org/2/items/respiracion-cuadrada/respiracion-cuadrada.mp4', img: 'https://images.unsplash.com/photo-1713428856048-d52b6474b5f7?q=80&w=1170&auto=format&fit=crop' },
    { title: 'Descanso visual', src: 'https://ia600604.us.archive.org/33/items/descanso-visual/descanso-visual.mp4', img: 'https://plus.unsplash.com/premium_photo-1661304634388-28a1f48892ab?q=80&w=1169&auto=format&fit=crop' },
    { title: 'Relajación muscular', src: 'https://ia601408.us.archive.org/31/items/relajacion-muscular/relajacion-muscular.mp4', img: 'https://plus.unsplash.com/premium_photo-1682094607329-ee8bb3968762?q=80&w=1170&auto=format&fit=crop' },
    { title: 'Meditación de gratitud', src: 'https://ia903106.us.archive.org/1/items/gratitud_202604/gratitud.mp4', img: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773' },
    { title: 'Movilidad de manos y muñecas', src: 'https://ia902805.us.archive.org/10/items/movilidad_202604/movilidad.mp4', img: 'https://plus.unsplash.com/premium_photo-1679164458634-163862c284bd?q=80&w=687&auto=format&fit=crop' }
];

let currentTrackIndex = 0;
const video = document.getElementById('main-video');
const player = document.getElementById('video-player');
const playPauseBtn = document.getElementById('play-pause-btn');
const progressBar = document.getElementById('progress-bar');
const notch = document.getElementById('phone-notch');

function loadTrack(index) {
    currentTrackIndex = index;
    const track = playlist[index];
    if(track) {
        document.getElementById('p-title').innerText = track.title;
        video.src = track.src;
        video.load();
        progressBar.style.width = '0%';
    }
}

function openPlayer(index) {
    loadTrack(index);
    player.style.display = 'flex';
    if(notch) notch.style.background = 'transparent';
    video.play().catch(e => console.log("Error al reproducir video:", e));
    playPauseBtn.innerText = '⏸';
}

// --- FUNCIÓN PARA GUARDAR PROGRESO EN BD ---
function guardarProgresoEnBD() {
    const tiempoActual = Math.floor(video.currentTime);
    
    // Guardamos solo si vio más de 5 segundos
    if (tiempoActual > 5) { 
        const minutos = Math.floor(tiempoActual / 60);
        const segundos = tiempoActual % 60;
        const tiempoFormateado = minutos + ":" + (segundos < 10 ? '0' : '') + segundos + " min";
        
        const titulo = document.getElementById('p-title').innerText;
        // Obtenemos la imagen de nuestra lista para que la tarjeta en Home se vea bien
        const imagen = playlist[currentTrackIndex].img; 

        const params = new URLSearchParams();
        params.append('titulo', titulo);
        params.append('imagen', imagen);
        params.append('tiempo', tiempoFormateado);

        fetch('../GuardarProgresoServlet', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params.toString()
        }).then(() => console.log("Progreso de video guardado"))
          .catch(err => console.error("Error al guardar video:", err));
    }
}

function closePlayer() {
    guardarProgresoEnBD(); // Guardar antes de ocultar
    player.style.display = 'none';
    if(notch) notch.style.background = 'black';
    video.pause();
}

function togglePlay() {
    if (video.paused) {
        video.play();
        playPauseBtn.innerText = '⏸';
    } else {
        video.pause();
        playPauseBtn.innerText = '▶︎';
    }
}

function nextTrack() {
    currentTrackIndex = (currentTrackIndex + 1) % playlist.length;
    loadTrack(currentTrackIndex);
    video.play();
    playPauseBtn.innerText = '⏸';
}

function prevTrack() {
    currentTrackIndex = (currentTrackIndex - 1 + playlist.length) % playlist.length;
    loadTrack(currentTrackIndex);
    video.play();
    playPauseBtn.innerText = '⏸';
}

video.addEventListener('timeupdate', () => {
    if (video.duration > 0) {
        let progressWidth = (video.currentTime / video.duration) * 100;
        progressBar.style.width = progressWidth + "%";
    }
});

video.addEventListener('ended', nextTrack);

const progContainer = document.getElementById('progress-container');
if(progContainer) {
    progContainer.addEventListener('click', function(e) {
        const width = this.clientWidth;
        const clickX = e.offsetX;
        video.currentTime = (clickX / width) * video.duration;
    });
}

window.onload = function() {
    const urlParams = new URLSearchParams(window.location.search);
    const tituloURL = urlParams.get('titulo');
    const tiempoURL = urlParams.get('tiempo');

    if (tituloURL && tiempoURL) {
        // 1. Buscar el contenido en la lista de meditación
        const index = playlist.findIndex(t => t.title === tituloURL);
        
        if (index !== -1) {
            openPlayer(index); // Esta función ya debe cargar el src del video/audio

            // 2. Convertir "min:seg min" a segundos puros
            const partes = tiempoURL.replace(' min', '').split(':');
            const segundosTotales = (parseInt(partes[0]) * 60) + parseInt(partes[1]);

            // 3. OBTENER EL ELEMENTO (Asegúrate que el ID coincida con tu tag <video> o <audio>)
            const mediaElement = document.getElementById('main-video') || document.getElementById('main-audio');

            if (mediaElement) {
                // ESCUCHAR CUANDO LOS METADATOS ESTÉN LISTOS
                mediaElement.onloadedmetadata = function() {
                    console.log("Metadatos cargados, saltando al segundo: " + segundosTotales);
                    mediaElement.currentTime = segundosTotales;
                    mediaElement.play(); // Iniciar reproducción en ese punto
                };

                // Caso de respaldo: Si los metadatos ya estaban cargados por el openPlayer
                if (mediaElement.readyState >= 1) {
                    mediaElement.currentTime = segundosTotales;
                }
            }
        }
    }
};

</script>

    
</body>
</html>