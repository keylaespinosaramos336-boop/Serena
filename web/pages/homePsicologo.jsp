<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%-- IMPORTACIONES NECESARIAS --%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.serena.Cita" %>

<%
    // 1. RECUPERAR NOMBRE DEL USUARIO
    String nombreCompleto = (String) session.getAttribute("nombreUsuario");
    String primerNombre = (nombreCompleto != null && !nombreCompleto.trim().isEmpty()) 
                          ? nombreCompleto.trim().split(" ")[0] 
                          : "Usuario";

    // 2. CONFIGURACIÓN DE CONEXIÓN
    String URL = System.getenv().getOrDefault("DB_URL", "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&serverTimezone=UTC");
    String USER = System.getenv().getOrDefault("DB_USER", "root");
    String PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    List<Map<String, String>> listaPacientes = new ArrayList<>();
    List<Cita> listaCitas = new ArrayList<>();
    
    Connection con = null;
    PreparedStatement st = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(URL, USER, PASS);
        
        // --- Cargar Pacientes ---
        String sql = "SELECT id_usuario, nombre FROM usuario WHERE tipo_usuario IN ('normal', 'empleado')";
        st = con.prepareStatement(sql);
        rs = st.executeQuery();
        while (rs.next()) {
            Map<String, String> paciente = new HashMap<>();
            paciente.put("id", rs.getString("id_usuario"));
            paciente.put("nombre", rs.getString("nombre"));
            listaPacientes.add(paciente);
        }
        
        // --- Cargar Citas (Si es psicólogo) ---
        Integer idPsicologoLogueado = (Integer) session.getAttribute("idPsicologo");
        if (idPsicologoLogueado != null) {
            String sqlCitas = "SELECT c.id_cita, u.nombre, c.fecha, c.hora, c.modalidad " +
                              "FROM cita c JOIN usuario u ON c.id_usuario = u.id_usuario " +
                              "WHERE c.id_psicologo = ? AND c.estado = 'pendiente' " + 
                              "ORDER BY c.fecha ASC, c.hora ASC";
            
            // Reutilizamos el PreparedStatement para cerrar el anterior
            st.close(); 
            st = con.prepareStatement(sqlCitas);
            st.setInt(1, idPsicologoLogueado);
            rs.close();
            rs = st.executeQuery();
            
            while (rs.next()) {
                listaCitas.add(new Cita(
                    rs.getInt("id_cita"),
                    rs.getString("nombre"),
                    rs.getString("fecha"),
                    rs.getString("hora"),
                    rs.getString("modalidad")
                ));
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        // MUY IMPORTANTE: Cerrar recursos para no saturar Railway
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (st != null) st.close(); } catch (SQLException e) {}
        try { if (con != null) con.close(); } catch (SQLException e) {}
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Inicio Psicólogo - Serena</title>
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

        /* MARCO TELEFONO */
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
          height:140px;
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


        /* SECCIONES */
        .section-title{
          font-size:15px;
          font-weight:700;
          margin:15px 0 10px 0;
        }

        /* LISTADO DE CITAS */
        .appointments-list{
          display:flex;
          flex-direction:column;
          gap:10px;
        }

        .appointment-item{
          background: rgba(255,255,255,0.15);
          padding:12px 15px;
          border-radius:12px;
          display:flex;
          justify-content:space-between;
          align-items:center;
          flex-wrap: wrap;
        }

        .appointment-info{
          display:flex;
          flex-direction:column;
        }

        .patient-name{
          font-weight:600;
          font-size:14px;
        }

        .appointment-time{
          font-size:12px;
          opacity:0.8;
          margin-bottom:5px;
        }

        .appointment-actions{
          display:flex;
          gap:5px;
          margin-top:5px;
        }

        .appointment-actions button{
          background: rgba(255,255,255,0.25);
          border:none;
          color:white;
          font-size:11px;
          font-weight:600;
          padding:4px 8px;
          border-radius:8px;
          cursor:pointer;
        }

        .appointment-actions button:hover{
          background: rgba(255,255,255,0.4);
        }

        /* CALENDARIO */
        .calendar{
          margin-top:15px;
          background: rgba(255,255,255,0.15);
          border-radius:15px;
          padding:10px;
        }

        .calendar-days{
          display:grid;
          grid-template-columns: repeat(7,1fr);
          gap:5px;
        }

        .calendar-day{
          background: rgba(255,255,255,0.25);
          border-radius:8px;
          text-align:center;
          padding:8px 0;
          font-size:12px;
          cursor:pointer;
          user-select: none;
          color:white;
          font-weight:600;
        }

        .calendar-day:hover{
          background: rgba(255,255,255,0.45);
        }

        .calendar-day.today{
          background: #4c6ef5;
        }

        /* POPUP AGREGAR CITA CENTRADO */
        .add-appointment-popup{
          position:absolute;
          background:white;
          color:black;
          padding:12px;
          border-radius:12px;
          width:220px;
          font-size:12px;
          top:50%;
          left:50%;
          transform:translate(-50%,-50%);
          display:none;
          z-index:50;
          box-shadow:0 5px 15px rgba(0,0,0,0.3);
        }

        .add-appointment-popup label{
          display:block;
          margin-top:8px;
          font-size:12px;
        }

        .add-appointment-popup input{
          width:100%;
          padding:5px;
          border-radius:6px;
          border:1px solid #ccc;
          font-size:12px;
          margin-top:3px;
        }

        .add-appointment-popup button{
          margin-top:8px;
          padding:6px 0;
          border:none;
          border-radius:8px;
          background:#4c6ef5;
          color:white;
          font-weight:600;
          cursor:pointer;
          width:100%;
        }

        .add-appointment-popup button.cancel{
          background:#aaa;
        }

        /* MENÚ INFERIOR */
        .menu {
            position: absolute;
            bottom: 0;
            left: 0;      /* <--- Agrega esto para resetear la posición horizontal */
            width: 100%;
            height: 70px;
            background: rgba(0, 0, 0, 0.7); /* Un poco más oscuro para mejor contraste */
            display: flex;
            justify-content: space-around;
            align-items: center;
            font-size: 12px;
            box-sizing: border-box; /* <--- Asegura que el padding no estire el ancho */
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

        .radio-group {
            display: flex;
            gap: 15px;
            margin-bottom: 15px;
            margin-top: 5px;
        }

        .radio-option {
            display: flex;
            align-items: center;
            gap: 5px;
            font-size: 13px;
            cursor: pointer;
            background: #f0f4f8;
            padding: 6px 10px;
            border-radius: 8px;
            transition: 0.2s;
        }

        .radio-option:hover {
            background: #e2e8f0;
        }

        /* Estilo del circulito del radio */
        .radio-option input[type="radio"] {
            width: 15px;
            height: 15px;
            accent-color: #4c6ef5; /* Color azul de tu app */
            margin: 0;
        }

        .calendar-controls {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 15px 0 10px 0;
            padding: 0 5px;
        }

        .calendar-controls span {
            font-size: 15px;
            font-weight: 700;
        }

        .calendar-controls button {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: 0.2s;
        }

        .calendar-controls button:hover {
            background: rgba(255, 255, 255, 0.4);
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
                    <h1>Buenos días, Dr. <%= primerNombre %></h1>
                    <p>“Hoy es un buen día para tus pacientes.”</p>
                </div>
            </div>
                    <div class="content">
                        <div class="section-title">Proximas citas</div>
                        <div class="appointments-list">
                            <%
                                if (listaCitas != null && !listaCitas.isEmpty()) {
                                    for (Cita cita : listaCitas) {
                            %>
                                <div class="appointment-item">
                                    <div class="appointment-info">
                                        <span class="patient-name"><%= cita.getNombrePaciente() %></span>
                                        <span class="appointment-time">
                                            <strong><%= cita.getFecha() %></strong> a las <%= cita.getHora() %>
                                            <br>
                                            <span style="font-size: 10px; color: #add8e6;"><%= cita.getModalidad().toUpperCase() %></span>
                                        </span>
                                        <div class="appointment-actions">
                                            <button type="button" style="background: rgba(255,0,0);">Cancelar</button>
                                            <button type="button">Reagendar</button>
                                        </div>
                                    </div>
                                </div>
                            <% 
                                    }
                                } else {
                            %>
                                <div class="appointment-item" style="justify-content: center;">
                                    <span class="appointment-time">No hay citas pendientes en tu agenda.</span>
                                </div>
                            <% } %>
                        </div>
                        
                        <div class="section-title">Calendario</div>
                        <div class="appointments-list" id="main-list"></div>

                        <div class="calendar-controls" style="display: flex; justify-content: space-between; align-items: center; padding: 10px;">
                            <button type="button" onclick="changeMonth(-1)">&#10094;</button> 
                            <span id="month-name" style="font-size: 18px; font-weight: 700; color: white; flex-grow: 1; text-align: center;"></span>
                            <button type="button" onclick="changeMonth(1)">&#10095;</button> 
                        </div>

                        <div class="calendar">
                            <div class="calendar-days" id="calendar-grid"></div>
                        </div>

                        <!-- POPUP AGREGAR CITA -->
                        <div class="add-appointment-popup" id="popup">
                            <h3>Agregar Cita</h3>
                            <form action="../GuardarCitaServlet" method="POST" id="formCita">
                                <label>Seleccionar Paciente:</label>
                                <select name="id_usuario_paciente" required style="width:100%; padding:8px; border-radius:8px; margin-top:5px;">
                                    <option value="">-- Seleccione un paciente --</option>
                                    <% 
                                       if(listaPacientes != null) {
                                           for (Map<String, String> p : listaPacientes) { 
                                    %>
                                    <option value="<%= p.get("id") %>"><%= p.get("nombre") %></option>
                                    <% 
                                           } 
                                       } 
                                    %>
                                    </select>

                                    <label>Fecha seleccionada:</label>
                                    <input type="hidden" name="fecha_cita" id="hidden_fecha">
                                    <input type="text" id="display_fecha" disabled 
                                           style="background:#f0f0f0; border:1px solid #ccc; color:#333; font-weight:bold;">

                                    <label>Hora:</label>
                                    <input type="time" name="hora_cita" required>

                                    <label>Modalidad:</label>
                                    <div class="radio-group">
                                        <label class="radio-option"><input type="radio" name="modalidad" value="virtual" checked> Virtual</label>
                                        <label class="radio-option"><input type="radio" name="modalidad" value="presencial"> Presencial</label>
                                    </div>

                                    <button type="button" onclick="guardarCita()" style="background:#4c6ef5; color:white; margin-top:15px;">Guardar Cita</button>
                                    <button type="button" class="cancel" onclick="cerrarPopup()" style="background:#aaa;">Cancelar</button>
                            </form>
                        </div>
                                    
                        <div class="menu">
                            <div class="active">🏠<br>Home</div>
                            <div>💬<br>Chat</div>
                            <div>📊<br>Reportes</div>
                            <div>👤<br>Perfil</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
                                    

        <script>
            // --- ESTADO GLOBAL ---
            let date = new Date();
            let currentMonth = date.getMonth(); 
            let currentYear = date.getFullYear();

            // --- FUNCIONES DEL CALENDARIO ---
            function renderCalendar(year, month) {
                const grid = document.getElementById('calendar-grid');
                const monthTitle = document.getElementById('month-name');
                const names = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

                monthTitle.innerText = names[month] + " " + year;
                grid.innerHTML = ''; 

                const dayLabels = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
                dayLabels.forEach(label => {
                    const div = document.createElement('div');
                    div.className = 'calendar-day header-day';
                    div.style.background = "transparent";
                    div.style.cursor = "default";
                    div.innerText = label;
                    grid.appendChild(div);
                });

                let firstDayIndex = new Date(year, month, 1).getDay();
                const daysInMonth = new Date(year, month + 1, 0).getDate();

                for (let i = 0; i < firstDayIndex; i++) {
                    grid.appendChild(document.createElement('div'));
                }

                const today = new Date();
                for (let day = 1; day <= daysInMonth; day++) {
                    const dayBtn = document.createElement('div');
                    dayBtn.className = 'calendar-day';
                    dayBtn.innerText = day;

                    if (day === today.getDate() && month === today.getMonth() && year === today.getFullYear()) {
                        dayBtn.classList.add('today');
                    }

                    // AL HACER CLIC EN UN DÍA
                    dayBtn.onclick = () => {
                        // Preparamos la fecha para MySQL (YYYY-MM-DD)
                        let mesSQL = (month + 1).toString().padStart(2, '0');
                        let diaSQL = day.toString().padStart(2, '0');
                        let fechaCompleta = year + "-" + mesSQL + "-" + diaSQL;

                        // Llenamos los campos del popup
                        document.getElementById('hidden_fecha').value = fechaCompleta;
                        document.getElementById('display_fecha').value = day + " de " + names[month] + " " + year;

                        // Mostramos el popup
                        document.getElementById('popup').style.display = 'block';
                    };
                    grid.appendChild(dayBtn);
                }
            }

            function changeMonth(delta) {
                currentMonth += delta;
                if (currentMonth > 11) { currentMonth = 0; currentYear++; }
                if (currentMonth < 0) { currentMonth = 11; currentYear--; }
                renderCalendar(currentYear, currentMonth);
            }

            function cerrarPopup() {
                document.getElementById('popup').style.display = 'none';
            }

            function guardarCita() {
                // 1. Obtenemos el formulario y los campos
                const formulario = document.getElementById('formCita');
                const paciente = formulario.id_usuario_paciente.value;
                const fecha = document.getElementById('hidden_fecha').value;
                const hora = formulario.hora_cita.value;

                // 2. Validaciones manuales (puedes agregar las que quieras)
                if (!paciente) {
                    alert("Por favor, selecciona un paciente.");
                    return;
                }
                if (!fecha) {
                    alert("Error: No se ha detectado la fecha. Por favor, toca un día del calendario.");
                    return;
                }
                if (!hora) {
                    alert("Por favor, selecciona una hora para la cita.");
                    return;
                }

                // 3. Si todo está bien, enviamos el formulario a Serena
                console.log("Enviando cita para la fecha: " + fecha);
                formulario.submit(); 
            }

            // Carga inicial
            renderCalendar(currentYear, currentMonth);
        </script>
</body>
</html>