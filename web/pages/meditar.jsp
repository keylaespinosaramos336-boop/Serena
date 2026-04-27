<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Meditación - Serena</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

<style>
* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: 'Plus Jakarta Sans', sans-serif;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
}

/* ══════════════════════════════
   ESCRITORIO: fondo gris + marco
   ══════════════════════════════ */
@media (min-width: 768px) {
    body { background: #e6e6e6; }

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
        flex-shrink: 0;
    }
    .phone {
        width: 340px;
        height: 680px;
        border-radius: 40px;
        overflow: hidden;
    }
    .notch {
        display: block;
        width: 120px;
        height: 25px;
        background: black;
        border-radius: 0 0 20px 20px;
        position: absolute;
        top: 0;
        left: 50%;
        transform: translateX(-50%);
        z-index: 110;
    }
}

/* ══════════════════════════════
   MÓVIL: pantalla completa, sin marco
   ══════════════════════════════ */
@media (max-width: 767px) {
    body {
        background: linear-gradient(180deg, #6aa3d6, #3f6ba9);
        align-items: stretch;
        min-height: 100dvh;
    }
    .phone-frame {
        width: 100%;
        flex: 1;
        display: flex;
        background: transparent;
        box-shadow: none;
        padding: 0;
        border-radius: 0;
    }
    .phone {
        width: 100%;
        height: 100dvh;
        border-radius: 0;
    }
    .notch { display: none; }
}

/* ══════════════════════════════
   PANTALLA INTERNA
   ══════════════════════════════ */
.phone {
    background: linear-gradient(180deg, #6aa3d6, #3f6ba9);
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
    z-index: 110;
}

/* HEADER: tamaño fijo */
.header {
    padding: 40px 25px 25px 25px;
    text-align: center;
    font-size: 22px;
    font-weight: bold;
    flex-shrink: 0;
}

/* CONTENIDO: ocupa espacio restante y hace scroll */
.container {
    flex: 1;
    min-height: 0; /* clave para que flex + overflow funcionen */
    background: rgba(0,0,0,0.25);
    border-radius: 30px 30px 0 0;
    padding: 20px;
    overflow-y: auto;
    -webkit-overflow-scrolling: touch;
    scrollbar-width: none;
    -ms-overflow-style: none;
}

.container::-webkit-scrollbar { display: none; }

.grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
}

.card {
    height: 200px;
    border-radius: 18px;
    background-size: cover;
    background-position: center;
    display: flex;
    align-items: flex-end;
    padding: 10px;
    font-weight: bold;
    cursor: pointer;
    transition: 0.2s;
}

.card:hover { transform: scale(1.05); }

.card span {
    background: rgba(0,0,0,0.5);
    padding: 5px 8px;
    border-radius: 8px;
    font-size: 13px;
}

/* ══════════════════════════════
   REPRODUCTOR DE VIDEO
   ══════════════════════════════ */
#video-player {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: black;
    z-index: 100;
    display: none;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

.player-video-element {
    width: 280px;
    height: 280px;
    border-radius: 20px;
    object-fit: cover;
    box-shadow: 0 15px 35px rgba(0,0,0,0.5);
}

.close-btn {
    position: absolute;
    top: 45px; left: 25px;
    font-size: 24px;
    cursor: pointer;
    color: white;
    opacity: 0.8;
    z-index: 102;
}

.player-content-block {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
    padding-top: 20px;
}

.player-info {
    text-align: left;
    width: 260px;
    margin-top: 35px;
}

.player-info h2 { margin: 0; font-size: 20px; font-weight: 700; }
.player-info p  { margin: 5px 0 0; opacity: 0.7; font-size: 14px; }

.progress-container {
    width: 260px;
    height: 4px;
    background: rgba(255,255,255,0.2);
    margin-top: 30px;
    border-radius: 2px;
    cursor: pointer;
}

.progress-bar {
    width: 0%;
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
    color: white;
}

.control-btn { cursor: pointer; opacity: 0.8; transition: 0.2s; }
.control-btn:hover { opacity: 1; transform: scale(1.1); }
.play-btn { font-size: 45px; }

/* MENÚ: flex item fijo al fondo, nunca se comprime */
.menu {
    flex-shrink: 0;
    width: 100%;
    height: 70px;
    background: rgba(0,0,0,0.504);
    display: flex;
    justify-content: space-around;
    align-items: center;
    font-size: 12px;
    z-index: 50;
}

.menu div {
    text-align: center;
    cursor: pointer;
    padding: 8px 10px;
    border-radius: 12px;
    transition: 0.2s;
    color: white;
}

.menu .active {
    background: rgba(255,255,255,0.25);
    transform: scale(1.05);
    font-weight: bold;
}
</style>
</head>

<body>

<div class="phone-frame">
<div class="phone">

    <div class="notch" id="phone-notch"></div>

    <!-- REPRODUCTOR DE VIDEO (overlay absoluto) -->
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

    <!-- HEADER FIJO -->
    <div class="header">Pausas activas</div>

    <!-- CONTENIDO QUE HACE SCROLL -->
    <div class="container">
        <div class="grid">

            <div class="card" onclick="openPlayer(0)" style="background-image:url('https://plus.unsplash.com/premium_photo-1661438486473-78494571fbeb?q=80&w=1170&auto=format&fit=crop');">
                <span>Estiramiento en silla</span>
            </div>

            <div class="card" onclick="openPlayer(1)" style="background-image:url('https://images.unsplash.com/photo-1713428856048-d52b6474b5f7?q=80&w=1170&auto=format&fit=crop');">
                <span>Respiración cuadrada</span>
            </div>

            <div class="card" onclick="openPlayer(2)" style="background-image:url('https://plus.unsplash.com/premium_photo-1661304634388-28a1f48892ab?q=80&w=1169&auto=format&fit=crop');">
                <span>Descanso visual</span>
            </div>

            <div class="card" onclick="openPlayer(3)" style="background-image:url('https://plus.unsplash.com/premium_photo-1682094607329-ee8bb3968762?q=80&w=1170&auto=format&fit=crop');">
                <span>Relajación muscular</span>
            </div>

            <div class="card" onclick="openPlayer(4)" style="background-image:url('https://images.unsplash.com/photo-1506126613408-eca07ce68773');">
                <span>Meditación de gratitud</span>
            </div>

            <div class="card" onclick="openPlayer(5)" style="background-image:url('https://plus.unsplash.com/premium_photo-1679164458634-163862c284bd?q=80&w=687&auto=format&fit=crop');">
                <span>Movilidad de muñecas y manos</span>
            </div>

        </div>
    </div>

    <!-- MENÚ FIJO ABAJO (flex item, no absolute) -->
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
const playlist = [
    { title: 'Estiramientos en silla',        src: 'https://ia902907.us.archive.org/9/items/estiramiento-silla/estiramiento-silla.mp4',       img: 'https://plus.unsplash.com/premium_photo-1661438486473-78494571fbeb?q=80&w=1170&auto=format&fit=crop' },
    { title: 'Respiración cuadrada',           src: 'https://ia903206.us.archive.org/2/items/respiracion-cuadrada/respiracion-cuadrada.mp4',   img: 'https://images.unsplash.com/photo-1713428856048-d52b6474b5f7?q=80&w=1170&auto=format&fit=crop' },
    { title: 'Descanso visual',                src: 'https://ia600604.us.archive.org/33/items/descanso-visual/descanso-visual.mp4',             img: 'https://plus.unsplash.com/premium_photo-1661304634388-28a1f48892ab?q=80&w=1169&auto=format&fit=crop' },
    { title: 'Relajación muscular',            src: 'https://ia601408.us.archive.org/31/items/relajacion-muscular/relajacion-muscular.mp4',     img: 'https://plus.unsplash.com/premium_photo-1682094607329-ee8bb3968762?q=80&w=1170&auto=format&fit=crop' },
    { title: 'Meditación de gratitud',         src: 'https://ia903106.us.archive.org/1/items/gratitud_202604/gratitud.mp4',                    img: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773' },
    { title: 'Movilidad de manos y muñecas',   src: 'https://ia902805.us.archive.org/10/items/movilidad_202604/movilidad.mp4',                 img: 'https://plus.unsplash.com/premium_photo-1679164458634-163862c284bd?q=80&w=687&auto=format&fit=crop' }
];

let currentTrackIndex = 0;
const video        = document.getElementById('main-video');
const player       = document.getElementById('video-player');
const playPauseBtn = document.getElementById('play-pause-btn');
const progressBar  = document.getElementById('progress-bar');
const notch        = document.getElementById('phone-notch');

function loadTrack(index) {
    currentTrackIndex = index;
    const track = playlist[index];
    if (track) {
        document.getElementById('p-title').innerText = track.title;
        video.src = track.src;
        video.load();
        progressBar.style.width = '0%';
    }
}

function openPlayer(index) {
    loadTrack(index);
    player.style.display = 'flex';
    if (notch) notch.style.background = 'transparent';
    video.play().catch(e => console.log("Error al reproducir video:", e));
    playPauseBtn.innerText = '⏸';
}

function guardarProgresoEnBD() {
    const tiempoActual = Math.floor(video.currentTime);
    if (tiempoActual > 5) {
        const minutos  = Math.floor(tiempoActual / 60);
        const segundos = tiempoActual % 60;
        const tiempoFormateado = minutos + ":" + (segundos < 10 ? '0' : '') + segundos + " min";
        const params = new URLSearchParams();
        params.append('titulo', document.getElementById('p-title').innerText);
        params.append('imagen', playlist[currentTrackIndex].img);
        params.append('tiempo', tiempoFormateado);
        fetch('../GuardarProgresoServlet', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params.toString()
        }).catch(err => console.error("Error al guardar video:", err));
    }
}

function closePlayer() {
    guardarProgresoEnBD();
    player.style.display = 'none';
    if (notch) notch.style.background = 'black';
    video.pause();
}

function togglePlay() {
    if (video.paused) { video.play(); playPauseBtn.innerText = '⏸'; }
    else              { video.pause(); playPauseBtn.innerText = '▶︎'; }
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
    if (video.duration > 0)
        progressBar.style.width = (video.currentTime / video.duration * 100) + "%";
});

video.addEventListener('ended', nextTrack);

const progContainer = document.getElementById('progress-container');
if (progContainer) {
    progContainer.addEventListener('click', function(e) {
        video.currentTime = (e.offsetX / this.clientWidth) * video.duration;
    });
}

window.onload = function() {
    const urlParams = new URLSearchParams(window.location.search);
    const tituloURL = urlParams.get('titulo');
    const tiempoURL = urlParams.get('tiempo');

    if (tituloURL && tiempoURL) {
        const index = playlist.findIndex(t => t.title === tituloURL);
        if (index !== -1) {
            openPlayer(index);
            const partes = tiempoURL.replace(' min', '').split(':');
            const seg = (parseInt(partes[0]) * 60) + parseInt(partes[1]);
            video.onloadedmetadata = function() {
                video.currentTime = seg;
                video.play();
            };
            if (video.readyState >= 1) video.currentTime = seg;
        }
    }
};
</script>

</body>
</html>
