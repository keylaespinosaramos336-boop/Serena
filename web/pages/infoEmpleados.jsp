<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

    // ─── VERIFICAR SESIÓN DE EMPRESA ───────────────────────────────────────────
    Integer idEmpresa = (Integer) session.getAttribute("idEmpresa");
    String  tipoUsuario = (String) session.getAttribute("tipoUsuario");

    if (idEmpresa == null || !"empresa".equalsIgnoreCase(tipoUsuario)) {
        response.sendRedirect("login.html");
        return;
    }

    // ─── CONFIGURACIÓN BD ──────────────────────────────────────────────────────
    String DB_URL  = System.getenv().getOrDefault("DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8");
    String DB_USER = System.getenv().getOrDefault("DB_USER", "root");
    String DB_PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    // ─── ACCIÓN: DAR DE BAJA ───────────────────────────────────────────────────
    String accion        = request.getParameter("accion");
    String idBajaParam   = request.getParameter("idUsuario");
    String mensajeError  = "";

    if ("darDeBaja".equals(accion) && idBajaParam != null) {
        try {
            int idBaja = Integer.parseInt(idBajaParam);
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

                // Verificar que el usuario pertenece a esta empresa antes de borrar
                String sqlVerifica = "SELECT id_usuario FROM usuario WHERE id_usuario = ? AND id_Empresa = ?";
                try (PreparedStatement psV = con.prepareStatement(sqlVerifica)) {
                    psV.setInt(1, idBaja);
                    psV.setInt(2, idEmpresa);
                    ResultSet rsV = psV.executeQuery();

                    if (rsV.next()) {
                        Statement st = con.createStatement();
                        st.execute("SET FOREIGN_KEY_CHECKS=0");

                        String sqlDelete = "DELETE FROM usuario WHERE id_usuario = ? AND id_Empresa = ?";
                        try (PreparedStatement ps = con.prepareStatement(sqlDelete)) {
                            ps.setInt(1, idBaja);
                            ps.setInt(2, idEmpresa);
                            ps.executeUpdate();
                        }
                        st.execute("SET FOREIGN_KEY_CHECKS=1");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            mensajeError = "Error al dar de baja al empleado.";
        }
        // Redirigir para evitar reenvío del formulario (PRG pattern)
        response.sendRedirect("infoEmpleados.jsp?baja=ok");
        return;
    }

    // ─── PARÁMETRO DE BÚSQUEDA ─────────────────────────────────────────────────
    String busqueda = request.getParameter("buscar");
    if (busqueda == null) busqueda = "";
    busqueda = busqueda.trim();

    // ─── LISTA DE EMPLEADOS ────────────────────────────────────────────────────
    // Estructura: {id, nombre, correo, fecha_registro, foto}
    List<Map<String, String>> empleados = new ArrayList<>();
    String nombreEmpresa = "Mi Empresa";
    int totalEmpleados   = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

            // Nombre de la empresa
            String sqlEmp = "SELECT nombre FROM empresa WHERE id_empresa = ?";
            try (PreparedStatement ps = con.prepareStatement(sqlEmp)) {
                ps.setInt(1, idEmpresa);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) nombreEmpresa = rs.getString("nombre");
            }

            // Empleados — con búsqueda opcional por nombre
            String sqlEmp2 = "SELECT id_usuario, nombre, correo, fecha_registro, foto " +
                             "FROM usuario " +
                             "WHERE id_Empresa = ? AND tipo_usuario = 'empleado'" +
                             (busqueda.isEmpty() ? "" : " AND nombre LIKE ?") +
                             " ORDER BY nombre ASC";

            try (PreparedStatement ps = con.prepareStatement(sqlEmp2)) {
                ps.setInt(1, idEmpresa);
                if (!busqueda.isEmpty()) ps.setString(2, "%" + busqueda + "%");

                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, String> emp = new LinkedHashMap<>();
                    emp.put("id",      String.valueOf(rs.getInt("id_usuario")));
                    emp.put("nombre",  rs.getString("nombre") != null ? rs.getString("nombre") : "Sin nombre");
                    emp.put("correo",  rs.getString("correo") != null ? rs.getString("correo")  : "—");
                    emp.put("fecha",   rs.getString("fecha_registro") != null
                                       ? rs.getString("fecha_registro").substring(0, 10)
                                       : "—");
                    emp.put("foto",    rs.getString("foto") != null
                                       ? rs.getString("foto")
                                       : "https://img.icons8.com/3d-sugary/100/generic-user.png");
                    empleados.add(emp);
                }
            }

            // Total real (sin filtro de búsqueda)
            String sqlTotal = "SELECT COUNT(*) FROM usuario WHERE id_Empresa = ? AND tipo_usuario = 'empleado'";
            try (PreparedStatement ps = con.prepareStatement(sqlTotal)) {
                ps.setInt(1, idEmpresa);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) totalEmpleados = rs.getInt(1);
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
        mensajeError = "Error al conectar con la base de datos.";
    }

    boolean bajOk = "ok".equals(request.getParameter("baja"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Trabajadores - Serena</title>
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
  padding:40px 25px 15px 25px;
  text-align:center;
  background:rgba(0,0,0,0.2);
  border-bottom:1px solid rgba(255,255,255,0.2);
}

.header h1{
  margin:0;
  font-size:22px;
  font-weight:bold;
}

.header p{
  margin:3px 0 0 0;
  font-size:13px;
  opacity:0.8;
}

.content{
  flex:1;
  padding:10px 0 90px 0;
  overflow-y:auto;
  scrollbar-width:none;
}
.content::-webkit-scrollbar { display:none; }

.section-title{
  font-size:14px;
  font-weight:700;
  margin:12px 15px 8px 15px;
}

/* BUSCADOR */
.search-bar{
  margin:10px 15px 10px 15px;
  display:flex;
  gap:5px;
}

.search-bar input{
  flex:1;
  padding:8px 10px;
  border-radius:12px;
  border:none;
  font-size:12px;
  outline:none;
}

.search-bar button{
  padding:8px 10px;
  border:none;
  border-radius:12px;
  background:rgba(255,255,255,0.3);
  color:white;
  font-weight:bold;
  cursor:pointer;
  transition:0.2s;
}

.search-bar button:hover{
  background:rgba(255,255,255,0.5);
}

/* TARJETAS TRABAJADORES */
.worker-card{
  background:rgba(255,255,255,0.15);
  margin:8px 15px;
  padding:10px;
  border-radius:15px;
  display:flex;
  justify-content:space-between;
  align-items:center;
  gap:8px;
}

.worker-avatar{
  width:40px;
  height:40px;
  border-radius:50%;
  object-fit:cover;
  border:2px solid rgba(255,255,255,0.4);
  flex-shrink:0;
}

.worker-info{
  flex:1;
  display:flex;
  flex-direction:column;
  min-width:0;
}

.worker-info h4{
  margin:0;
  font-size:13px;
  font-weight:600;
  white-space:nowrap;
  overflow:hidden;
  text-overflow:ellipsis;
}

.worker-info p{
  margin:2px 0 0 0;
  font-size:11px;
  opacity:0.75;
  white-space:nowrap;
  overflow:hidden;
  text-overflow:ellipsis;
}

.worker-info .time{
  font-size:10px;
  opacity:0.55;
  margin-top:2px;
}

.worker-actions button{
  padding:6px 8px;
  border:none;
  border-radius:10px;
  cursor:pointer;
  font-size:11px;
  font-weight:bold;
  transition:0.2s;
  white-space:nowrap;
}

.worker-actions .remove{
  background:#ff4d4d;
  color:white;
}

.worker-actions .remove:hover{
  background:#ff1a1a;
}

/* ESTADO VACÍO */
.empty-state{
  text-align:center;
  padding:30px 20px;
  opacity:0.7;
  font-size:13px;
}

.empty-state .emoji{
  font-size:36px;
  display:block;
  margin-bottom:8px;
}

/* TOAST */
.toast{
  position:absolute;
  top:35px;
  left:50%;
  transform:translateX(-50%);
  background:#28a745;
  color:white;
  padding:8px 16px;
  border-radius:20px;
  font-size:11px;
  font-weight:600;
  z-index:50;
  white-space:nowrap;
  animation:fadeInOut 3s forwards;
}

@keyframes fadeInOut{
  0%   { opacity:0; transform:translateX(-50%) translateY(-8px); }
  15%  { opacity:1; transform:translateX(-50%) translateY(0);    }
  80%  { opacity:1; transform:translateX(-50%) translateY(0);    }
  100% { opacity:0; transform:translateX(-50%) translateY(-8px); }
}

/* MODAL CONFIRMACIÓN */
.modal-overlay{
  position:absolute;
  top:0; left:0;
  width:100%; height:100%;
  background:rgba(0,0,0,0.6);
  display:none;
  justify-content:center;
  align-items:center;
  z-index:100;
  backdrop-filter:blur(3px);
  border-radius:40px;
}

.modal-content{
  background:white;
  width:80%;
  padding:20px;
  border-radius:20px;
  text-align:center;
  color:#333;
  box-shadow:0 10px 25px rgba(0,0,0,0.2);
}

.modal-content h3{ margin:0 0 8px 0; font-size:15px; color:#ff4d4d; }
.modal-content p { font-size:11px; color:#666; margin-bottom:18px; }
.modal-content strong { color:#333; }

.modal-buttons{
  display:flex;
  flex-direction:column;
  gap:8px;
}

.modal-buttons button{
  padding:11px;
  border-radius:12px;
  border:none;
  font-weight:600;
  cursor:pointer;
  font-size:13px;
}

.btn-confirmar{ background:#ff4d4d; color:white; }
.btn-cancelar { background:#eee; color:#333; }

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
  backdrop-filter:blur(10px);
}

.menu div{
  text-align:center;
  cursor:pointer;
  padding:8px 10px;
  border-radius:12px;
  transition:0.2s;
  color:rgba(255,255,255,0.8);
}

.menu .active{
  background:rgba(255,255,255,0.25);
  transform:scale(1.05);
  font-weight:bold;
  color:white;
}
</style>
</head>
<body>

<div class="phone-frame">
  <div class="phone">
    <div class="notch"></div>

    <!-- TOAST DE ÉXITO -->
    <% if (bajOk) { %>
    <div class="toast">✅ Empleado dado de baja correctamente</div>
    <% } %>

    <!-- HEADER -->
    <div class="header">
      <h1>Trabajadores</h1>
      <p><%= nombreEmpresa %> · <%= totalEmpleados %> empleado<%= totalEmpleados != 1 ? "s" : "" %></p>
    </div>

    <div class="content">

      <!-- BUSCADOR -->
      <form method="GET" action="infoEmpleados.jsp" style="margin:0;">
        <div class="search-bar">
          <input type="text"
                 name="buscar"
                 placeholder="Buscar trabajador..."
                 value="<%= busqueda.isEmpty() ? "" : busqueda.replace("\"","&quot;") %>">
          <button type="submit">🔍</button>
        </div>
      </form>

      <!-- MENSAJE DE ERROR -->
      <% if (!mensajeError.isEmpty()) { %>
        <div style="margin:0 15px; padding:8px; background:rgba(255,77,77,0.3); border-radius:10px; font-size:12px;">
          ⚠️ <%= mensajeError %>
        </div>
      <% } %>

      <!-- RESULTADO DE BÚSQUEDA -->
      <% if (!busqueda.isEmpty()) { %>
        <div class="section-title">
          <%= empleados.size() %> resultado<%= empleados.size() != 1 ? "s" : "" %> para "<%= busqueda %>"
          &nbsp;<a href="infoEmpleados.jsp" style="color:rgba(255,255,255,0.7); font-size:11px;">✕ Limpiar</a>
        </div>
      <% } else { %>
        <div class="section-title">Equipo activo</div>
      <% } %>

      <!-- LISTADO DINÁMICO DE EMPLEADOS -->
      <% if (empleados.isEmpty()) { %>
        <div class="empty-state">
          <span class="emoji"><%= busqueda.isEmpty() ? "👥" : "🔍" %></span>
          <%= busqueda.isEmpty()
              ? "No hay empleados registrados en esta empresa."
              : "No se encontró ningún empleado con ese nombre." %>
        </div>
      <% } else {
           for (Map<String, String> emp : empleados) { %>
        <div class="worker-card">
          <img class="worker-avatar"
               src="<%= emp.get("foto") %>"
               alt="Foto de <%= emp.get("nombre") %>"
               onerror="this.src='https://img.icons8.com/3d-sugary/100/generic-user.png'">

          <div class="worker-info">
            <h4><%= emp.get("nombre") %></h4>
            <p><%= emp.get("correo") %></p>
            <p class="time">Desde: <%= emp.get("fecha") %></p>
          </div>

          <div class="worker-actions">
            <button class="remove"
                    onclick="abrirModalBaja('<%= emp.get("id") %>', '<%= emp.get("nombre").replace("'", "\\'") %>')">
              Dar de baja
            </button>
          </div>
        </div>
      <% }
         } %>

    </div><!-- /content -->

    <!-- MENU INFERIOR -->
    <div class="menu">
      <div onclick="location.href='homeEmpresa.jsp';">🏠<br>Home</div>
      <div class="active">👨‍💼<br>Empleados</div>
      <div onclick="location.href='perfilEmpresa.jsp';">👤<br>Perfil</div>
    </div>

    <!-- MODAL CONFIRMACIÓN DAR DE BAJA -->
    <div id="modalBaja" class="modal-overlay">
      <div class="modal-content">
        <h3>⚠️ Dar de baja</h3>
        <p>¿Estás seguro de que deseas dar de baja a<br><strong id="modalNombre"></strong>?<br><br>Esta acción eliminará su acceso de forma permanente.</p>
        <div class="modal-buttons">
          <button class="btn-confirmar" onclick="confirmarBaja()">Dar de baja definitivamente</button>
          <button class="btn-cancelar" onclick="cerrarModal()">Cancelar</button>
        </div>
      </div>
    </div>

  </div><!-- /phone -->
</div><!-- /phone-frame -->

<script>
  let idBajaPendiente = null;

  function abrirModalBaja(idUsuario, nombre) {
    idBajaPendiente = idUsuario;
    document.getElementById('modalNombre').innerText = nombre;
    document.getElementById('modalBaja').style.display = 'flex';
  }

  function cerrarModal() {
    document.getElementById('modalBaja').style.display = 'none';
    idBajaPendiente = null;
  }

  function confirmarBaja() {
    if (!idBajaPendiente) return;

    // Crear form POST dinámico (igual que en perfil.jsp)
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = 'infoEmpleados.jsp';

    const inputAccion = document.createElement('input');
    inputAccion.type  = 'hidden';
    inputAccion.name  = 'accion';
    inputAccion.value = 'darDeBaja';

    const inputId = document.createElement('input');
    inputId.type  = 'hidden';
    inputId.name  = 'idUsuario';
    inputId.value = idBajaPendiente;

    form.appendChild(inputAccion);
    form.appendChild(inputId);
    document.body.appendChild(form);
    form.submit();
  }

  // Cerrar modal al click fuera
  document.getElementById('modalBaja').addEventListener('click', function(e) {
    if (e.target === this) cerrarModal();
  });
</script>

</body>
</html>
