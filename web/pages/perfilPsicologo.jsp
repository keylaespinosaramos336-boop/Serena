<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.serena.Psicologo" %>

<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

    String URL  = System.getenv().getOrDefault("DB_URL",  "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC");
    String USER = System.getenv().getOrDefault("DB_USER", "root");
    String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    Integer idPsicologo = (Integer) session.getAttribute("idPsicologo");

    /* ── Redirigir si no hay sesión ── */
    if (idPsicologo == null) {
        response.sendRedirect("login.html");
        return;
    }

    /* ══════════════════════════════════════════════════
       PROCESAMIENTO POST
    ══════════════════════════════════════════════════ */
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String accion = request.getParameter("accion");
        try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {

            /* ── Eliminar foto ── */
            if ("eliminarFoto".equals(accion)) {
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE usuario SET foto = NULL " +
                    "WHERE id_usuario = (SELECT id_usuario FROM psicologo WHERE id_psicologo = ?)");
                ps.setInt(1, idPsicologo);
                ps.executeUpdate();

            /* ── Actualizar perfil ── */
            } else if ("actualizarPerfil".equals(accion)) {

                // 1. Nombre en tabla usuario
                PreparedStatement psU = conn.prepareStatement(
                    "UPDATE usuario SET nombre = ? " +
                    "WHERE id_usuario = (SELECT id_usuario FROM psicologo WHERE id_psicologo = ?)");
                psU.setString(1, request.getParameter("nombre"));
                psU.setInt(2, idPsicologo);
                psU.executeUpdate();

                // 2. Datos profesionales en tabla psicologo (sin tocar cédula)
                PreparedStatement psP = conn.prepareStatement(
                    "UPDATE psicologo SET especialidad = ?, experiencia = ?, modalidad = ? " +
                    "WHERE id_psicologo = ?");
                psP.setString(1, request.getParameter("especialidad"));
                psP.setString(2, request.getParameter("experiencia"));
                psP.setString(3, request.getParameter("modalidad"));
                psP.setInt(4, idPsicologo);
                psP.executeUpdate();

                // 3. Foto (Base64) si viene
                String nuevaFoto = request.getParameter("fotoBase64");
                if (nuevaFoto != null && !nuevaFoto.isEmpty()) {
                    PreparedStatement psF = conn.prepareStatement(
                        "UPDATE usuario SET foto = ? " +
                        "WHERE id_usuario = (SELECT id_usuario FROM psicologo WHERE id_psicologo = ?)");
                    psF.setString(1, nuevaFoto);
                    psF.setInt(2, idPsicologo);
                    psF.executeUpdate();
                }

            /* ── Cerrar sesión ── */
            } else if ("cerrarSesion".equals(accion)) {
                session.invalidate();
                response.sendRedirect("login.html");
                return;
            }

        } catch (Exception e) { e.printStackTrace(); }

        response.sendRedirect("perfilPsicologo.jsp");
        return;
    }

    /* ══════════════════════════════════════════════════
       CARGA DE DATOS
    ══════════════════════════════════════════════════ */
    Psicologo p = null;
    int sesionesAtendidas = 0;
    int numeroPacientes   = 0;

    try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {

        // Datos personales + profesionales
        String sql =
            "SELECT u.id_usuario, u.nombre, u.foto, " +
            "       ps.especialidad, ps.cedula, ps.experiencia, ps.modalidad " +
            "FROM usuario u " +
            "JOIN psicologo ps ON u.id_usuario = ps.id_usuario " +
            "WHERE ps.id_psicologo = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, idPsicologo);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            p = new Psicologo(
                rs.getInt("id_usuario"),
                rs.getString("nombre"),
                rs.getString("especialidad"),
                rs.getString("foto"),
                rs.getString("experiencia"),
                rs.getString("cedula"),
                rs.getString("modalidad")
            );
        }

        // Sesiones atendidas: citas ya pasadas (confirmadas o pendientes con fecha < hoy)
        PreparedStatement psSes = conn.prepareStatement(
            "SELECT COUNT(*) FROM cita " +
            "WHERE id_psicologo = ? AND fecha < CURDATE() AND estado != 'cancelada'");
        psSes.setInt(1, idPsicologo);
        ResultSet rsSes = psSes.executeQuery();
        if (rsSes.next()) sesionesAtendidas = rsSes.getInt(1);

        // Número de pacientes distintos
        PreparedStatement psPac = conn.prepareStatement(
            "SELECT COUNT(DISTINCT id_usuario) FROM cita WHERE id_psicologo = ? AND estado != 'cancelada'");
        psPac.setInt(1, idPsicologo);
        ResultSet rsPac = psPac.executeQuery();
        if (rsPac.next()) numeroPacientes = rsPac.getInt(1);

    } catch (Exception e) { e.printStackTrace(); }

    // Valores seguros para la vista
    String nombreMostrar       = (p != null && p.getNombre()       != null) ? p.getNombre()       : "Usuario";
    String especialidadMostrar = (p != null && p.getEspecialidad() != null) ? p.getEspecialidad() : "";
    String experienciaMostrar  = (p != null && p.getExperiencia()  != null) ? p.getExperiencia()  : "";
    String modalidadMostrar    = (p != null && p.getModalidad()    != null) ? p.getModalidad()    : "online";
    String cedula              = (p != null && p.getCedula()       != null) ? p.getCedula()       : "N/A";
    String fotoSrc             = (p != null && p.getFoto()         != null)
                                    ? p.getFoto()
                                    : "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
%>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Perfil Psicólogo - Serena</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">

<style>
/* ════════ BASE ════════ */
body {
    margin: 0;
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    background: #e6e6e6;
    font-family: 'Plus Jakarta Sans', sans-serif;
}

/* ════════ MARCO TELÉFONO ════════ */
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

/* ════════ PANTALLA ════════ */
.phone {
    width: 340px;
    height: 680px;
    background: linear-gradient(180deg, #6aa3d6, #3f6ba9);
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

/* ════════ HEADER / FOTO ════════ */
.header {
    padding: 45px 20px 15px 20px;
    text-align: center;
}

.profile-pic {
    width: 110px;
    height: 110px;
    border-radius: 50%;
    object-fit: cover;
    border: 4px solid rgba(255,255,255,0.4);
    display: block;
    margin: 0 auto 8px;
}

.profile-name {
    font-size: 17px;
    font-weight: 700;
    margin: 6px 0 2px;
}

.profile-role {
    font-size: 12px;
    opacity: 0.8;
    margin-bottom: 8px;
}

.image-actions {
    display: flex;
    gap: 8px;
    justify-content: center;
    margin-top: 6px;
}

.action-btn {
    padding: 6px 12px;
    border: none;
    border-radius: 15px;
    font-size: 10px;
    font-weight: 600;
    cursor: pointer;
    transition: 0.2s;
}
.btn-change { background: white; color: #3f6ba9; }
.btn-delete { background: rgba(255,255,255,0.2); color: white; }

/* ════════ CONTENIDO ════════ */
.content {
    flex: 1;
    background: rgba(0,0,0,0.25);
    border-radius: 30px 30px 0 0;
    padding: 20px;
    overflow-y: auto;
    padding-bottom: 90px;
    scrollbar-width: none;
    -ms-overflow-style: none;
}
.content::-webkit-scrollbar { display: none; }

.section-title {
    font-size: 14px;
    font-weight: 700;
    margin: 14px 0 8px;
}

/* ════════ TARJETAS ════════ */
.card {
    background: rgba(255,255,255,0.15);
    padding: 10px 12px;
    border-radius: 12px;
    margin-bottom: 8px;
    font-size: 13px;
}

/* ════════ STATS ════════ */
.stats {
    display: flex;
    justify-content: space-around;
    margin: 14px 0;
}
.stat { text-align: center; }
.stat h3 { margin: 0; font-size: 18px; }
.stat p  { margin: 0; font-size: 11px; opacity: 0.8; }

/* ════════ OPCIONES ════════ */
.option {
    background: rgba(255,255,255,0.15);
    padding: 12px;
    border-radius: 12px;
    margin-bottom: 10px;
    font-size: 13px;
    cursor: pointer;
    transition: background 0.2s;
}
.option:hover { background: rgba(255,255,255,0.25); }

/* ════════ MENÚ ════════ */
.menu {
    position: absolute;
    bottom: 0;
    width: 100%;
    height: 65px;
    background: rgba(0,0,0,0.6);
    display: flex;
    justify-content: space-around;
    align-items: center;
    font-size: 11px;
    backdrop-filter: blur(5px);
}
.menu div {
    text-align: center;
    cursor: pointer;
    color: rgba(255,255,255,0.7);
}
.menu .active {
    color: white;
    font-weight: bold;
}

/* ════════ MODAL OVERLAY ════════ */
.modal-overlay {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.65);
    display: none;
    justify-content: center;
    align-items: center;
    z-index: 200;
    backdrop-filter: blur(3px);
}

.modal-content {
    background: white;
    width: 82%;
    max-height: 78%;
    overflow-y: auto;
    padding: 20px;
    border-radius: 20px;
    color: #333;
    box-shadow: 0 10px 25px rgba(0,0,0,0.3);
    scrollbar-width: none;
}
.modal-content::-webkit-scrollbar { display: none; }
.modal-content h3 { margin: 0 0 10px; font-size: 15px; color: #3f6ba9; text-align: center; }

/* ════════ INPUTS DENTRO DEL MODAL ════════ */
.modal-input {
    width: 100%;
    box-sizing: border-box;
    padding: 9px 10px;
    margin-bottom: 10px;
    border-radius: 8px;
    border: 1px solid #ccc;
    font-size: 13px;
    font-family: 'Plus Jakarta Sans', sans-serif;
}

.modal-input:focus { outline: none; border-color: #3f6ba9; }

/* ════════ BOTONES MODAL ════════ */
.modal-buttons { display: flex; flex-direction: column; gap: 8px; margin-top: 12px; }
.modal-buttons button {
    padding: 11px;
    border-radius: 12px;
    border: none;
    font-weight: 600;
    font-size: 13px;
    cursor: pointer;
    font-family: 'Plus Jakarta Sans', sans-serif;
}
.btn-confirmar { background: #3f6ba9; color: white; }
.btn-cancelar  { background: #eee;    color: #333; }
.btn-peligro   { background: #ff4757; color: white; }

/* Preview foto en modal editar */
.preview-edit {
    width: 65px;
    height: 65px;
    border-radius: 50%;
    object-fit: cover;
    display: block;
    margin: 0 auto 12px;
    border: 2px solid #3f6ba9;
}

/* Toast */
.toast-success {
    position: fixed;
    top: 20px; right: 20px;
    background: #28a745;
    color: white;
    padding: 14px 22px;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    z-index: 9999;
    animation: fadeInOut 4s forwards;
    font-family: 'Plus Jakarta Sans', sans-serif;
}
@keyframes fadeInOut {
    0%   { opacity:0; transform:translateY(-20px); }
    10%  { opacity:1; transform:translateY(0); }
    90%  { opacity:1; }
    100% { opacity:0; }
}

/* Verificación pdf */
.upload-box {
    background: rgba(255,255,255,0.15);
    padding: 14px;
    border-radius: 12px;
    text-align: center;
    font-size: 12px;
    margin-bottom: 12px;
}
.upload-box input { margin-top: 8px; }
</style>
</head>

<body>

<div class="phone-frame">
<div class="phone">

    <div class="notch"></div>

    <!-- ════════ HEADER ════════ -->
    <div class="header">
        <input type="file" id="inputFotoRapida" style="display:none;" accept="image/*" onchange="subirFotoRapida()">

        <img src="<%= fotoSrc %>" class="profile-pic" id="profilePic">

        <div class="profile-name">Dr. <%= nombreMostrar %></div>
        <div class="profile-role"><%= especialidadMostrar %></div>

        <div class="image-actions">
            <button class="action-btn btn-change" onclick="document.getElementById('inputFotoRapida').click()">📷 Cambiar</button>
            <button class="action-btn btn-delete" onclick="abrirModal('modalEliminarFoto')">🗑️ Eliminar</button>
        </div>
    </div>

    <!-- ════════ CONTENIDO ════════ -->
    <div class="content">

        <div class="section-title">Información profesional</div>
        <div class="card"><strong>Cédula:</strong> <%= cedula %></div>
        <div class="card"><strong>Especialidad:</strong> <%= especialidadMostrar %></div>
        <div class="card"><strong>Experiencia:</strong> <%= experienciaMostrar %> años</div>
        <div class="card"><strong>Modalidad:</strong> <%= modalidadMostrar %></div>

        <div class="section-title">Verificación profesional</div>
        <div class="upload-box">
            Subir documento de cédula profesional (PDF)<br>
            <input type="file" accept="application/pdf">
        </div>

        <div class="section-title">Actividad en la app</div>
        <div class="stats">
            <div class="stat">
                <h3><%= sesionesAtendidas %></h3>
                <p>Sesiones atendidas</p>
            </div>
            <div class="stat">
                <h3><%= numeroPacientes %></h3>
                <p>Pacientes</p>
            </div>
        </div>

        <div class="section-title">Opciones</div>
        <div class="option" onclick="abrirModal('modalEditarPerfil')">Editar perfil profesional</div>
        <div class="option" onclick="abrirModal('modalCerrarSesion')">Cerrar sesión</div>

    </div>

    <!-- ════════ MENÚ ════════ -->
    <div class="menu">
        <div onclick="location.href='homePsicologo.jsp'">🏠<br>Home</div>
        <div onclick="location.href='chatPsicologo.jsp'">💬<br>Chat</div>
        <div onclick="location.href='reportes.jsp'">📊<br>Reportes</div>
        <div class="active">👤<br>Perfil</div>
    </div>

    <!-- ════════ MODAL: EDITAR PERFIL ════════ -->
    <div id="modalEditarPerfil" class="modal-overlay">
        <div class="modal-content">
            <h3>Editar Perfil</h3>

            <input type="file" id="inputFotoEditar" style="display:none;" accept="image/*" onchange="previsualizarFotoEditar()">
            <img id="previewFotoEditar" src="<%= fotoSrc %>" class="preview-edit">

            <button class="action-btn btn-change" style="margin: 0 auto 12px; display:block;"
                    onclick="document.getElementById('inputFotoEditar').click()">
                📷 Cambiar foto
            </button>

            <label style="font-size:12px; font-weight:600; color:#555;">Nombre</label>
            <input type="text" id="editNombre" class="modal-input"
                   value="<%= nombreMostrar %>">

            <label style="font-size:12px; font-weight:600; color:#555;">Especialidad</label>
            <input type="text" id="editEspecialidad" class="modal-input"
                   value="<%= especialidadMostrar %>">

            <label style="font-size:12px; font-weight:600; color:#555;">Experiencia (años)</label>
            <input type="text" id="editExperiencia" class="modal-input"
                   value="<%= experienciaMostrar %>">

            <label style="font-size:12px; font-weight:600; color:#555;">Modalidad</label>
            <select id="editModalidad" class="modal-input">
                <option value="online"      <%= "online".equals(modalidadMostrar)      ? "selected" : "" %>>Online</option>
                <option value="presencial"  <%= "presencial".equals(modalidadMostrar)  ? "selected" : "" %>>Presencial</option>
                <option value="mixto"       <%= "mixto".equals(modalidadMostrar)       ? "selected" : "" %>>Mixto</option>
            </select>

            <div class="modal-buttons">
                <button class="btn-confirmar" onclick="guardarCambiosPerfil()">Guardar Cambios</button>
                <button class="btn-cancelar"  onclick="cerrarModal('modalEditarPerfil')">Cancelar</button>
            </div>
        </div>
    </div>

    <!-- ════════ MODAL: ELIMINAR FOTO ════════ -->
    <div id="modalEliminarFoto" class="modal-overlay">
        <div class="modal-content">
            <h3>¿Eliminar foto de perfil?</h3>
            <p style="font-size:12px; color:#666; text-align:center;">Esta acción no se puede deshacer.</p>
            <div class="modal-buttons">
                <button class="btn-peligro"  onclick="confirmarEliminarFoto()">Sí, eliminar</button>
                <button class="btn-cancelar" onclick="cerrarModal('modalEliminarFoto')">Cancelar</button>
            </div>
        </div>
    </div>

    <!-- ════════ MODAL: CERRAR SESIÓN ════════ -->
    <div id="modalCerrarSesion" class="modal-overlay">
        <div class="modal-content">
            <h3 style="color:#ff4757;">Cerrar sesión</h3>
            <p style="font-size:12px; color:#666; text-align:center;">¿Estás seguro de que deseas salir de tu cuenta?</p>
            <div class="modal-buttons">
                <button class="btn-peligro"  onclick="cerrarSesion()">Sí, cerrar sesión</button>
                <button class="btn-cancelar" onclick="cerrarModal('modalCerrarSesion')">Cancelar</button>
            </div>
        </div>
    </div>

</div><!-- /phone -->
</div><!-- /phone-frame -->

<script>
/* ── Variable global para foto nueva ── */
let fotoBase64Nueva = "";

/* ── Helpers de modal ── */
function abrirModal(id)  { document.getElementById(id).style.display = 'flex'; }
function cerrarModal(id) { document.getElementById(id).style.display = 'none'; }

/* ── Foto rápida (botón Cambiar en header) ── */
function subirFotoRapida() {
    const file = document.getElementById('inputFotoRapida').files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function(e) {
        enviarPost({ accion: 'actualizarPerfil', fotoBase64: e.target.result,
                     nombre:        document.getElementById('editNombre')?.value        || '<%= nombreMostrar %>',
                     especialidad:  document.getElementById('editEspecialidad')?.value  || '<%= especialidadMostrar %>',
                     experiencia:   document.getElementById('editExperiencia')?.value   || '<%= experienciaMostrar %>',
                     modalidad:     document.getElementById('editModalidad')?.value     || '<%= modalidadMostrar %>' });
    };
    reader.readAsDataURL(file);
}

/* ── Previsualizar foto dentro del modal editar ── */
function previsualizarFotoEditar() {
    const file = document.getElementById('inputFotoEditar').files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function(e) {
        fotoBase64Nueva = e.target.result;
        document.getElementById('previewFotoEditar').src = fotoBase64Nueva;
    };
    reader.readAsDataURL(file);
}

/* ── Guardar cambios de perfil ── */
function guardarCambiosPerfil() {
    const nombre       = document.getElementById('editNombre').value.trim();
    const especialidad = document.getElementById('editEspecialidad').value.trim();
    const experiencia  = document.getElementById('editExperiencia').value.trim();
    const modalidad    = document.getElementById('editModalidad').value;

    if (!nombre) { alert("El nombre no puede estar vacío."); return; }

    const params = { accion: 'actualizarPerfil', nombre, especialidad, experiencia, modalidad };
    if (fotoBase64Nueva) params.fotoBase64 = fotoBase64Nueva;

    enviarPost(params);
}

/* ── Eliminar foto ── */
function confirmarEliminarFoto() {
    enviarPost({ accion: 'eliminarFoto' });
}

/* ── Cerrar sesión ── */
function cerrarSesion() {
    enviarPost({ accion: 'cerrarSesion' });
}

/* ── Utilidad: envío POST dinámico ── */
function enviarPost(params) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = 'perfilPsicologo.jsp';
    for (const key in params) {
        const input = document.createElement('input');
        input.type  = 'hidden';
        input.name  = key;
        input.value = params[key];
        form.appendChild(input);
    }
    document.body.appendChild(form);
    form.submit();
}

/* ── Toast de éxito (opcional, se puede llamar tras acciones) ── */
function mostrarToast(msg) {
    const t = document.createElement('div');
    t.className = 'toast-success';
    t.innerText = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 4000);
}
</script>

</body>
</html>
