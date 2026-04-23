<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Sueño - Serena</title>
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
    /* Flex column: header + container(crece) + menu(fijo abajo) */
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

/* CONTAINER: ocupa todo el espacio restante y hace scroll */
.container {
    flex: 1;
    background: rgba(0,0,0,0.25);
    border-radius: 30px 30px 0 0;
    padding: 20px 20px 20px 20px;
    overflow-y: auto;
    -webkit-overflow-scrolling: touch;
    scrollbar-width: none;
    -ms-overflow-style: none;
    min-height: 0; /* necesario para que flex+overflow funcionen */
}

.container::-webkit-scrollbar { display: none; }

/* GRID de tarjetas */
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
   REPRODUCTOR
   ══════════════════════════════ */
#spotify-player {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: linear-gradient(180deg, #2c3e50, #000000);
    z-index: 100;
    display: none;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding-top: 20px;
    transition: 0.5s ease-in-out;
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

.player-img {
    width: 260px; height: 260px;
    border-radius: 20px;
    object-fit: cover;
    box-shadow: 0 15px 35px rgba(0,0,0,0.5);
}

.player-info {
    text-align: left;
    width: 260px;
    margin-top: 35px;
}
.player-info h2 { margin: 0; font-size: 20px; font-weight: 700; }
.player-info p  { margin: 5px 0 0; opacity: 0.7; font-size: 14px; }

.progress-container {
    width: 260px; height: 4px;
    background: rgba(255,255,255,0.2);
    margin-top: 30px;
    border-radius: 2px;
    cursor: pointer;
}

.progress-bar {
    width: 0%; height: 100%;
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

/* ══════════════════════════════
   MENÚ — parte del flujo flex,
   siempre visible al fondo
   ══════════════════════════════ */
.menu {
    flex-shrink: 0;          /* nunca se comprime */
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

    <!-- REPRODUCTOR (overlay absoluto) -->
    <div id="spotify-player">
        <div class="close-btn" onclick="closePlayer()">✕</div>
        <div class="player-content-block">
            <img id="p-img" src="" class="player-img">
            <div class="player-info">
                <h2 id="p-title">Título</h2>
                <p>Relajación Serena</p>
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

    <!-- HEADER -->
    <div class="header">Sueño y relajación</div>

    <!-- CONTENIDO QUE HACE SCROLL -->
    <div class="container">
        <div class="grid">

            <div class="card" onclick="openPlayer(0)" style="background-image:url('https://images.unsplash.com/photo-1593923416234-c99746aff9c8?q=80&w=687&auto=format&fit=crop');">
                <span>Sonido de olas</span>
            </div>

            <div class="card" onclick="openPlayer(1)" style="background-image:url('https://plus.unsplash.com/premium_photo-1666717576644-5701d3406840?q=80&w=687&auto=format&fit=crop');">
                <span>Lluvia nocturna</span>
            </div>

            <div class="card" onclick="openPlayer(2)" style="background-image:url('https://images.unsplash.com/photo-1596326270561-cf62ad4f1d0b?q=80&w=677&auto=format&fit=crop');">
                <span>Campamento en el bosque</span>
            </div>

            <div class="card" onclick="openPlayer(3)" style="background-image:url('https://images.unsplash.com/photo-1519681393784-d120267933ba');">
                <span>ASMR relajante</span>
            </div>

            <div class="card" onclick="openPlayer(4)" style="background-image:url('https://images.unsplash.com/photo-1673105665361-79b1ef1c4b69?q=80&w=687&auto=format&fit=crop');">
                <span>Música para dormir</span>
            </div>

            <div class="card" onclick="openPlayer(5)" style="background-image:url('https://images.unsplash.com/photo-1512223886638-d2914abf5df3?q=80&w=1170&auto=format&fit=crop');">
                <span>Afirmaciones positivas</span>
            </div>

        </div>
    </div>

    <!-- MENÚ FIJO ABAJO (flex item, no absolute) -->
    <div class="menu">
        <div onclick="location.href='homeTrabajador.jsp';">🏠<br>Inicio</div>
        <div class="active">🌙<br>Sueño</div>
        <div onclick="location.href='meditar.jsp';">🧘<br>Meditar</div>
        <div onclick="location.href='audios.jsp';">🎵<br>Audios</div>
        <div onclick="location.href='${pageContext.request.contextPath}/ListarPsicologosServlet';">💬<br>Chat</div>
        <div onclick="location.href='perfil.jsp';">👤<br>Perfil</div>
    </div>

</div>
</div>

<script>
const playlist = [
    { title: 'Sonido de olas',          img: 'https://images.unsplash.com/photo-1593923416234-c99746aff9c8?q=80&w=687&auto=format&fit=crop', src: 'https://ia600406.us.archive.org/33/items/olas_20260419/olas.mp3' },
    { title: 'Lluvia nocturna',          img: 'https://plus.unsplash.com/premium_photo-1666717576644-5701d3406840?q=80&w=687&auto=format&fit=crop', src: 'https://ia600909.us.archive.org/25/items/lluvia_202604/lluvia.mp3' },
    { title: 'Campamento en el bosque',  img: 'https://images.unsplash.com/photo-1596326270561-cf62ad4f1d0b?q=80&w=677&auto=format&fit=crop', src: 'https://ia600804.us.archive.org/28/items/bosque_202604/bosque.mp3' },
    { title: 'ASMR relajante',           img: 'https://images.unsplash.com/photo-1519681393784-d120267933ba', src: 'https://ia600703.us.archive.org/33/items/asmr_20260419/asmr.mp3' },
    { title: 'Música para dormir',       img: 'https://images.unsplash.com/photo-1673105665361-79b1ef1c4b69?q=80&w=687&auto=format&fit=crop', src: 'https://ia600606.us.archive.org/31/items/musica_20260419/musica.mp3' },
    { title: 'Afirmaciones positivas',   img: 'https://images.unsplash.com/photo-1512223886638-d2914abf5df3?q=80&w=1170&auto=format&fit=crop', src: 'https://ia600706.us.archive.org/30/items/afirmaciones/afirmaciones.mp3' }
];

let currentTrackIndex = 0;
const audio        = document.getElementById('main-audio');
const player       = document.getElementById('spotify-player');
const playPauseBtn = document.getElementById('play-pause-btn');
const progressBar  = document.getElementById('progress-bar');
const notch        = document.getElementById('phone-notch');

function loadTrack(index) {
    currentTrackIndex = index;
    const track = playlist[index];
    document.getElementById('p-title').innerText = track.title;
    document.getElementById('p-img').src = track.img;
    audio.src = track.src;
    audio.load();
    progressBar.style.width = '0%';
}

function openPlayer(index) {
    loadTrack(index);
    player.style.display = 'flex';
    if (notch) notch.style.background = 'transparent';
    audio.play().catch(e => console.log("Error al reproducir:", e));
    playPauseBtn.innerText = '⏸';
}

function guardarProgresoEnBD() {
    const tiempoActual = Math.floor(audio.currentTime);
    if (tiempoActual > 5) {
        const minutos  = Math.floor(tiempoActual / 60);
        const segundos = tiempoActual % 60;
        const tiempoFormateado = minutos + ":" + (segundos < 10 ? '0' : '') + segundos + " min";
        const params = new URLSearchParams();
        params.append('titulo', document.getElementById('p-title').innerText);
        params.append('imagen', document.getElementById('p-img').src);
        params.append('tiempo', tiempoFormateado);
        fetch('../GuardarProgresoServlet', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params.toString()
        }).catch(err => console.error("Error al guardar progreso:", err));
    }
}

function closePlayer() {
    guardarProgresoEnBD();
    player.style.display = 'none';
    if (notch) notch.style.background = 'black';
    audio.pause();
}

function togglePlay() {
    if (audio.paused) { audio.play(); playPauseBtn.innerText = '⏸'; }
    else              { audio.pause(); playPauseBtn.innerText = '▶︎'; }
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

audio.addEventListener('timeupdate', () => {
    if (audio.duration > 0)
        progressBar.style.width = (audio.currentTime / audio.duration * 100) + "%";
});

document.getElementById('progress-container').addEventListener('click', function(e) {
    audio.currentTime = (e.offsetX / this.clientWidth) * audio.duration;
});

audio.addEventListener('ended', nextTrack);

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
            setTimeout(() => { audio.currentTime = seg; }, 100);
        }
    }
};
</script>

</body>
</html>