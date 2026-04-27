<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

    // 1. Asegurar sesión
    Integer idEmpresa = (Integer) session.getAttribute("idEmpresa");
    if (idEmpresa == null) {
        response.sendRedirect("login.html");
        return;
    }

    // Configuración de conexión
    String URL = System.getenv().getOrDefault("DB_URL", "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC");
    String USER = System.getenv().getOrDefault("DB_USER", "root");
    String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    // Variables iniciales
    String nombreEmpresa = "Sin nombre de empresa", razonSocial = "Sin razón social", direccion = "Sin dirección", correo = "Sin correo", codigo = "Sin código", foto = "https://img.icons8.com/?size=100&id=53373&format=png&color=000000";

    // 2. Lógica para procesar cambios (POST)
    String accion = request.getParameter("accion");
    if (accion != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(URL, USER, PASS);
            
            if ("editarPerfilEmpresa".equals(accion)) {
                // Si solo viene la foto (subirFoto rápida), no queremos sobrescribir nombre/razon con nulos
                String nuevoNombre = request.getParameter("nombre") != null ? request.getParameter("nombre") : nombreEmpresa;
                String nuevaRazon = request.getParameter("razon") != null ? request.getParameter("razon") : razonSocial;
                String nuevaDir = request.getParameter("direccion") != null ? request.getParameter("direccion") : direccion;
                String nuevaFoto = request.getParameter("foto");
                
                String sql = "UPDATE empresa SET nombre = ?, razon_social = ?, direccion = ?" + (nuevaFoto != null && !nuevaFoto.isEmpty() ? ", foto = ?" : "") + " WHERE id_empresa = ?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, nuevoNombre);
                ps.setString(2, nuevaRazon);
                ps.setString(3, nuevaDir);
                if (nuevaFoto != null && !nuevaFoto.isEmpty()) {
                    ps.setString(4, nuevaFoto);
                    ps.setInt(5, idEmpresa);
                } else {
                    ps.setInt(4, idEmpresa);
                }
                ps.executeUpdate();
            } else if ("eliminarFoto".equals(accion)) {
                PreparedStatement ps = con.prepareStatement("UPDATE empresa SET foto = NULL WHERE id_empresa = ?");
                ps.setInt(1, idEmpresa);
                ps.executeUpdate();
            }
            con.close();
            response.sendRedirect("perfilEmpresa.jsp"); // Recargar para mostrar cambios
            return;
        } catch(Exception e) { e.printStackTrace(); }
    }

    // 3. Consulta de datos para mostrar (GET)
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(URL, USER, PASS);
        PreparedStatement ps = con.prepareStatement("SELECT nombre, razon_social, direccion, correo, codigo_empresa, foto FROM empresa WHERE id_empresa = ?");
        ps.setInt(1, idEmpresa);
        ResultSet rs = ps.executeQuery();
        if(rs.next()){
            nombreEmpresa = rs.getString("nombre");
            razonSocial = rs.getString("razon_social");
            direccion = rs.getString("direccion");
            correo = rs.getString("correo");
            codigo = rs.getString("codigo_empresa");
            if(rs.getString("foto") != null) foto = rs.getString("foto");
        }
        con.close();
    } catch(Exception e) { e.printStackTrace(); }
%>


<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Perfil Empresa - Serena</title>
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

.header{
  padding:50px 25px 20px 25px;
  text-align:center;
}

.header h1{
  margin:0;
  font-size:20px;
  font-weight:bold;
}

.content{
  flex:1;
  padding:0 0 90px 0;
  overflow-y:auto;
  scrollbar-width:none;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.content::-webkit-scrollbar { display:none; }

.profile-container {
    text-align: center;
    margin-top: 10px;
}

.company-image-circle{
  width: 150px;
  height: 150px;
  border-radius: 50%;
  object-fit: cover;
  border: 4px solid rgba(255,255,255,0.4);
  box-shadow: 0 8px 20px rgba(0,0,0,0.2);
  display: block;
  margin: 0 auto;
}

.image-actions {
    display: flex;
    gap: 10px;
    justify-content: center;
    margin-top: 15px;
    margin-bottom: 20px;
}

.action-btn {
    padding: 8px 12px;
    border: none;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
    cursor: pointer;
    transition: 0.2s;
    display: flex;
    align-items: center;
    gap: 5px;
}

.btn-change { background: white; color: #3f6ba9; }
.btn-delete { background: rgba(255, 255, 255, 0.2); color: white; }
.action-btn:hover { transform: scale(1.05); opacity: 0.9; }

.company-info{
  width: 85%;
  margin: 10px 0;
  padding: 15px;
  background: rgba(255,255,255,0.15);
  border-radius: 20px;
  backdrop-filter: blur(5px);
}

.info-group {
    margin-bottom: 12px;
}

.company-info h4{
  margin: 0;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 1px;
  opacity: 0.7;
}

.company-info p{
  margin: 4px 0 0 0;
  font-size: 14px;
  font-weight: 500;
}

.edit-btn{
  width: 100%;
  margin-top: 10px;
  padding: 10px;
  border: none;
  border-radius: 12px;
  background: #00bfff;
  color: white;
  font-weight: bold;
  cursor: pointer;
  transition: 0.2s;
}

/* ===== SECCIÓN CÓDIGO DE EMPRESA ===== */
.code-section {
  width: 85%;
  margin: 10px 0 16px 0;
  padding: 16px;
  background: rgba(0, 0, 0, 0.25);
  border-radius: 20px;
  border: 1.5px solid rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(8px);
}

.code-section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.code-section-header span {
  font-size: 16px;
}

.code-section h3 {
  margin: 0;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.5px;
}

.code-section .subtitle {
  font-size: 11px;
  opacity: 0.65;
  margin: 0 0 14px 0;
  line-height: 1.4;
}

/* Caja de código generado */
.code-display {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: rgba(255,255,255,0.12);
  border-radius: 12px;
  padding: 10px 14px;
  margin-bottom: 12px;
  min-height: 40px;
}

.code-value {
  font-size: 20px;
  font-weight: 700;
  letter-spacing: 6px;
  color: #fff;
  font-variant-numeric: tabular-nums;
}

.code-placeholder {
  font-size: 13px;
  opacity: 0.45;
  font-style: italic;
}

.copy-btn {
  background: rgba(255,255,255,0.2);
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 14px;
  padding: 6px 8px;
  cursor: pointer;
  transition: 0.2s;
  flex-shrink: 0;
}
.copy-btn:hover { background: rgba(255,255,255,0.35); transform: scale(1.05); }
.copy-btn:active { transform: scale(0.95); }

/* Botones de acción del código */
.code-actions {
  display: flex;
  gap: 8px;
}

.gen-btn {
  flex: 1;
  padding: 10px;
  border: none;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
}

.btn-generate {
  background: linear-gradient(135deg, #00d4ff, #007bff);
  color: white;
  box-shadow: 0 4px 12px rgba(0, 123, 255, 0.35);
}

.btn-regenerate {
  background: rgba(255,255,255,0.15);
  color: white;
  border: 1px solid rgba(255,255,255,0.25);
}

.gen-btn:hover { transform: scale(1.03); opacity: 0.92; }
.gen-btn:active { transform: scale(0.97); }

/* Badge "Activo" */
.code-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: rgba(0, 220, 130, 0.2);
  border: 1px solid rgba(0, 220, 130, 0.5);
  color: #00dc82;
  font-size: 10px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 20px;
  margin-top: 10px;
  letter-spacing: 0.5px;
}

.code-badge .dot {
  width: 6px;
  height: 6px;
  background: #00dc82;
  border-radius: 50%;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(0.8); }
}

/* Toast de copiado */
.toast {
  position: absolute;
  top: 70px;
  left: 50%;
  transform: translateX(-50%) translateY(-10px);
  background: rgba(0,0,0,0.75);
  color: white;
  font-size: 11px;
  font-weight: 600;
  padding: 7px 16px;
  border-radius: 20px;
  backdrop-filter: blur(10px);
  opacity: 0;
  transition: opacity 0.3s, transform 0.3s;
  pointer-events: none;
  z-index: 20;
  white-space: nowrap;
}

.toast.show {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
}

/* MENU INFERIOR */
.menu{
  position:absolute;
  bottom:0;
  width:100%;
  height:70px;
  background:rgba(0,0,0,0.5);
  display:flex;
  justify-content:space-around;
  align-items:center;
  font-size:12px;
  backdrop-filter: blur(10px);
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
/* Estilos del Modal */
.modal-overlay {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0, 0, 0, 0.6);
    display: none; /* Escondido por defecto */
    justify-content: center;
    align-items: center;
    z-index: 100;
    backdrop-filter: blur(3px);
}

.modal-content {
    background: white;
    width: 80%;
    padding: 20px;
    border-radius: 20px;
    text-align: center;
    color: #333;
    box-shadow: 0 10px 25px rgba(0,0,0,0.2);
}

.modal-content h3 { margin: 0 0 10px 0; font-size: 15px; color: #3f6ba9; }
.modal-content p { font-size: 10px; color: #666; margin-bottom: 20px; }

.modal-buttons {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.modal-buttons button {
    padding: 12px;
    border-radius: 12px;
    border: none;
    font-weight: 600;
    cursor: pointer;
}

.btn-delete { background: rgba(255, 255, 255, 0.2); color: white; }

</style>
</head>
<body>

<div class="phone-frame">
  <div class="phone">
    <div class="notch"></div>
    <div class="toast" id="toast">✅ Código copiado</div>

    <div class="header">
      <h1>Perfil Corporativo</h1>
    </div>

    <div class="content">
      <div class="profile-container">
        <input type="file" id="inputFoto" style="display:none;" accept="image/*" onchange="subirFoto()">
        
        <img src="<%= foto %>" alt="Empresa" class="company-image-circle" id="profilePic">
        
        <div class="image-actions">
            <button class="action-btn btn-change" onclick="abrirGaleria()">📷 Cambiar</button>
            <button class="action-btn btn-delete" onclick="eliminarFoto()">🗑️ Eliminar</button>
        </div>
      </div>

      <div class="company-info">
        <div class="info-group">
            <h4>Nombre de la empresa</h4>
            <p><%= nombreEmpresa %></p>
        </div>
        
        <div class="info-group">
            <h4>Razón social</h4>
            <p><%= razonSocial %></p>
        </div>

        <div class="info-group">
            <h4>Dirección Sede</h4>
            <p><%= direccion %></p>
        </div>

        <div class="info-group">
            <h4>Contacto Oficial</h4>
            <p><%= correo %></p>
        </div>

        <button class="action-btn btn-change" onclick="abrirModalEditar()">✏️ Editar Datos de Cuenta</button>
      </div>

      <!-- SECCIÓN CÓDIGO DE ACCESO -->
      <div class="code-section">
        <div class="code-section-header">
          <span>🔑</span>
          <h3>Código de Acceso para Empleados</h3>
        </div>
        <p class="subtitle">Los empleados necesitan este código para unirse a tu empresa en la app.</p>

        <div class="code-display" id="codeDisplay">
          <span class="code-placeholder" id="codePlaceholder">Sin código generado</span>
          <span class="code-value" id="codeValue" style="display:none;"></span>
          <button class="copy-btn" id="copyBtn" style="display:none;" onclick="copyCode()">📋</button>
        </div>

        <div class="code-actions">
          <button class="gen-btn btn-generate" id="generateBtn" onclick="generateCode()">✨ Generar Código</button>
          <button class="gen-btn btn-regenerate" id="regenBtn" style="display:none;" onclick="generateCode()">🔄 Renovar</button>
        </div>

        <div class="code-badge" id="codeBadge" style="display:none;">
          <span class="dot"></span> ACTIVO
        </div>
      </div>

    </div>

    <div class="menu">
      <div onclick="location.href='${pageContext.request.contextPath}/pages/homeEmpresa.jsp';">🏠<br>Home</div>
      <div onclick="location.href='${pageContext.request.contextPath}/pages/infoEmpleados.jsp';">👨‍💼<br>Empleados</div>
      <div class="active">🏢<br>Perfil</div>
    </div>
        
        <div id="modalEliminar" class="modal-overlay">
            <div class="modal-content">
                <h3>¿Seguro que desea eliminar la foto de perfil?</h3>
                <p>Esta acción no se puede deshacer.</p>
                <div class="modal-buttons">
                    <button class="btn-confirmar" onclick="confirmarEliminacion()">Eliminar</button>
                    <button class="btn-cancelar" onclick="cerrarModal()">Cancelar</button>
                </div>
            </div>
        </div>
        
    <div id="modalEditarPerfil" class="modal-overlay">
    <div class="modal-content">
        <h3>Editar Datos de Empresa</h3>

        <input type="text" id="editNombre" value="<%= nombreEmpresa %>" placeholder="Nombre de la empresa" style="width:90%; margin-bottom:10px;">
        <input type="text" id="editRazon" value="<%= razonSocial %>" placeholder="Razón social" style="width:90%; margin-bottom:10px;">
        <input type="text" id="editDireccion" value="<%= direccion %>" placeholder="Dirección" style="width:90%; margin-bottom:10px;">
        <input type="text" id="editCorreo" value="<%= correo %>" placeholder="Correo" style="width:90%; margin-bottom:10px;">

        <p>Cambiar Logo:</p>
        <button class="action-btn btn-change" style="margin: 0 auto;" onclick="document.getElementById('inputFotoEditar').click()">📁 Seleccionar Imagen</button>
        <input type="file" id="inputFotoEditar" style="display:none;" accept="image/*" onchange="previsualizarEdicion()">
        <img id="previewEdit" src="<%= foto %>" style="width:60px; height:60px; border-radius:50%; display:block; margin:10px auto;">

        <div class="modal-buttons" style="margin-top: 15px;">
            <button onclick="guardarCambiosPerfil()" style="background: #3f6ba9; color: white; border: none;">Guardar Cambios</button>
            <button onclick="cerrarModalEditar()" style="background: #eee; border: none;">Cancelar</button>
        </div>
    </div>
</div>
        
       

  </div>
</div>

<script>
    
    let fotoBase64Nueva = "";
    
  function generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }

    // --- NUEVA LÓGICA PARA ENVIAR AL SERVIDOR ---
    fetch('../guardarCodigoServlet', { // Ruta de tu nuevo Servlet
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'codigo=' + code
    })
    .then(response => {
        if (response.ok) {
            // Si el servidor respondió bien, mostramos en la interfaz
            document.getElementById('codePlaceholder').style.display = 'none';
            document.getElementById('codeValue').style.display = 'block';
            document.getElementById('codeValue').textContent = code;
            document.getElementById('copyBtn').style.display = 'block';
            document.getElementById('codeBadge').style.display = 'inline-flex';
            document.getElementById('generateBtn').style.display = 'none';
            document.getElementById('regenBtn').style.display = 'flex';
        } else {
            alert("Error al guardar el código en el servidor");
        }
    });
}


    // --- FUNCIONES PARA MODAL EDITAR ---
    function previsualizarEdicion() {
        const file = document.getElementById('inputFotoEditar').files[0];
        const reader = new FileReader();
        reader.onloadend = function() {
            fotoBase64Nueva = reader.result;
            document.getElementById('previewEdit').src = fotoBase64Nueva;
        }
        if (file) reader.readAsDataURL(file);
    }

    function guardarCambiosPerfil() {
        enviarFormularioDinamico({ 
            accion: 'editarPerfilEmpresa', 
            nombre: document.getElementById('editNombre').value,
            razon: document.getElementById('editRazon').value,
            direccion: document.getElementById('editDireccion').value,
            correo: document.getElementById('editCorreo').value,
            foto: fotoBase64Nueva 
        });
    }

    // --- UTILIDAD DE ENVÍO ---
    function enviarFormularioDinamico(params) {
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = 'perfilEmpresa.jsp';

        for (const key in params) {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = key;
            input.value = params[key];
            form.appendChild(input);
        }
        document.body.appendChild(form);
        form.submit();
    }
    
    function abrirModalEditar() {
    abrirModalGeneral('modalEditarPerfil');
}



function subirFoto() {
    const input = document.getElementById('inputFoto');
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            // Cambiamos "valor" por "foto" para que coincida con el parámetro que espera Java
            enviarFormularioDinamico({ accion: 'editarPerfilEmpresa', foto: e.target.result });
        };
        reader.readAsDataURL(input.files[0]);
    }
}

function eliminarFoto() {
    abrirModalGeneral('modalEliminar');
}

// --- FUNCIONES PARA ABRIR/CERRAR MODALES ---
function abrirModalGeneral(id) {
    document.getElementById(id).style.display = 'flex';
}

function cerrarModal() {
    document.getElementById('modalEliminar').style.display = 'none';
}

// Corregimos las funciones de acción de foto
function abrirGaleria() {
    // Si quieres subir directo al hacer clic:
    document.getElementById('inputFoto').click();
}

function confirmarEliminacion() {
    // Redirige al mismo JSP pero con la acción de eliminar
    window.location.href = "perfilEmpresa.jsp?accion=eliminarFoto";
}

function cerrarModalEditar() {
    document.getElementById('modalEditarPerfil').style.display = 'none';
}

</script>

</body>
</html>
