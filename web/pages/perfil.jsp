<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %> 
<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

    Integer idUsuario = (Integer) session.getAttribute("idUsuario");
    if (idUsuario == null) {
        response.sendRedirect("login.html");
        return;
    }

    String accion = (request.getParameter("accion") != null) ? request.getParameter("accion").trim() : null;
    String dbUrl = "jdbc:mysql://localhost:3306/bd_serena?useUnicode=true&characterEncoding=UTF-8&useSSL=false";
    String dbUser = "root";
    String dbPass = "Keylabd2603";

    // --- VARIABLES DE DATOS ---
    String nombreUsuario = "Usuario";
    String nombreEmpresa = "Particular";
    String fotoPerfil = "https://img.icons8.com/3d-sugary/100/generic-user.png";
    String puntosGrafica = ""; 
    List<Integer> listaPorcentajes = new ArrayList<>();
    int nivelAnsiedad = 0, nivelEstres = 0, nivelDepresion = 0;
    
    // Variables de estadísticas de uso
    int racha = 0;
    int tiempoSegundosHoy = 0;
    int sesionesHoy = 0;
    String tiempoFormateado = "00:00:00"; // Nueva variable para el formato HH:mm:ss

    // --- LÓGICA DE ACCIONES (POST/UPDATE) ---
    if (accion != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
                if ("borrarCuenta".equals(accion)) {
                    // Paso 1: Por si acaso, desactivamos el chequeo de llaves (opcional pero seguro)
                    Statement st = con.createStatement();
                    st.execute("SET FOREIGN_KEY_CHECKS=0");

                    // Paso 2: Borramos al usuario
                    String sqlDelete = "DELETE FROM usuario WHERE id_usuario = ?";
                    try (PreparedStatement ps = con.prepareStatement(sqlDelete)) {
                        ps.setInt(1, idUsuario);
                        int filas = ps.executeUpdate();

                        // Paso 3: Reactivamos el chequeo
                        st.execute("SET FOREIGN_KEY_CHECKS=1");

                        if (filas > 0) {
                            // Limpiamos sesión y redirigimos
                            session.invalidate();
                            response.sendRedirect("login.html");
                            return;
                        } else {
                            out.println("<script>alert('Error: El usuario no existe o ya fue borrado.'); window.location='perfil.jsp';</script>");
                            return;
                        }
                    }
                }
                else if (accion.equals("foto")) {
                    String imagenBase64 = request.getParameter("valor");
                    PreparedStatement ps = con.prepareStatement("UPDATE usuario SET foto = ? WHERE id_usuario = ?");
                    ps.setString(1, imagenBase64);
                    ps.setInt(2, idUsuario);
                    ps.executeUpdate();
                } 
                else if (accion.equals("eliminarFoto")) {
                    PreparedStatement ps = con.prepareStatement("UPDATE usuario SET foto = NULL WHERE id_usuario = ?");
                    ps.setInt(1, idUsuario);
                    ps.executeUpdate();
                }
                else if (accion.equals("editarPerfil")) {
                    String nuevoNombre = request.getParameter("nombre");
                    String nuevaFoto = request.getParameter("foto");
                    boolean tieneFoto = (nuevaFoto != null && !nuevaFoto.isEmpty());
                    
                    String sql = "UPDATE usuario SET nombre = ?" + (tieneFoto ? ", foto = ?" : "") + " WHERE id_usuario = ?";
                    PreparedStatement ps = con.prepareStatement(sql);
                    ps.setString(1, nuevoNombre);
                    if (tieneFoto) {
                        ps.setString(2, nuevaFoto);
                        ps.setInt(3, idUsuario);
                    } else {
                        ps.setInt(2, idUsuario);
                    }
                    ps.executeUpdate();
                }
                else if (accion.equals("guardarTest")) {
                    int ans = Integer.parseInt(request.getParameter("ansiedad"));
                    int est = Integer.parseInt(request.getParameter("estres"));
                    int dep = Integer.parseInt(request.getParameter("depresion"));
                    PreparedStatement ps = con.prepareStatement("INSERT INTO autoevaluacion (id_usuario, ansiedad, estres, depresion, fecha) VALUES (?, ?, ?, ?, NOW())");
                    ps.setInt(1, idUsuario);
                    ps.setInt(2, ans);
                    ps.setInt(3, est);
                    ps.setInt(4, dep);
                    ps.executeUpdate();
                }
            }
            response.sendRedirect("perfil.jsp"); 
            return;
        } catch (Exception e) { e.printStackTrace(); }
    }

    // --- CONSULTA DE DATOS PARA MOSTRAR ---
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        
        // 1. Datos personales
        PreparedStatement psUser = con.prepareStatement("SELECT u.nombre, u.foto, e.nombre as empresa FROM usuario u LEFT JOIN empresa e ON u.id_empresa = e.id_empresa WHERE u.id_usuario = ?");
        psUser.setInt(1, idUsuario);
        ResultSet rsUser = psUser.executeQuery();
        if (rsUser.next()) {
            nombreUsuario = rsUser.getString("nombre");
            if(rsUser.getString("empresa") != null) nombreEmpresa = rsUser.getString("empresa");
            if(rsUser.getString("foto") != null) fotoPerfil = rsUser.getString("foto");
        }

        // 2. Gráfica (SVG)
        PreparedStatement psAnimo = con.prepareStatement("SELECT porcentaje FROM registroanimo WHERE id_usuario = ? ORDER BY fecha DESC LIMIT 8");
        psAnimo.setInt(1, idUsuario);
        ResultSet rsAnimo = psAnimo.executeQuery();
        while(rsAnimo.next()){
            listaPorcentajes.add(rsAnimo.getInt("porcentaje"));
        }
        Collections.reverse(listaPorcentajes);

        if (!listaPorcentajes.isEmpty()) {
            int totalPuntos = listaPorcentajes.size();
            for (int i = 0; i < totalPuntos; i++) {
                int x = (totalPuntos > 1) ? (i * 100 / (totalPuntos - 1)) : 100;
                int y = 100 - listaPorcentajes.get(i);
                puntosGrafica += x + "," + y + " ";
            }
        }

        // 3. Niveles Emocionales
        PreparedStatement psEval = con.prepareStatement("SELECT ansiedad, estres, depresion FROM autoevaluacion WHERE id_usuario = ? ORDER BY fecha DESC LIMIT 1");
        psEval.setInt(1, idUsuario);
        ResultSet rsEval = psEval.executeQuery();
        if(rsEval.next()){
            nivelAnsiedad = rsEval.getInt("ansiedad");
            nivelEstres = rsEval.getInt("estres");
            nivelDepresion = rsEval.getInt("depresion");
        }

        // 4. Estadísticas de Uso (Racha y Tiempo hoy)
        PreparedStatement psRacha = con.prepareStatement("SELECT COUNT(DISTINCT DATE(fecha)) as racha FROM autoevaluacion WHERE id_usuario = ?");
        psRacha.setInt(1, idUsuario);
        ResultSet rsRacha = psRacha.executeQuery();
        if(rsRacha.next()) racha = rsRacha.getInt("racha");

        // Tiempo y Sesiones de hoy
        PreparedStatement psTiempo = con.prepareStatement("SELECT tiempo_reproducido FROM progreso_reproduccion WHERE id_usuario = ? AND DATE(fecha) = CURDATE()");
        psTiempo.setInt(1, idUsuario);
        ResultSet rsTiempo = psTiempo.executeQuery();
        
        tiempoSegundosHoy = 0;
        sesionesHoy = 0;
        while(rsTiempo.next()){
            sesionesHoy++;
            String tStr = rsTiempo.getString("tiempo_reproducido");
            try {
                // Formato esperado: "6:59 min" o "06:59 min"
                String limpio = tStr.replace(" min", "").trim();
                String[] partes = limpio.split(":");
                int m = Integer.parseInt(partes[0]);
                int s = Integer.parseInt(partes[1]);
                tiempoSegundosHoy += (m * 60) + s;
            } catch(Exception e) {}
        }

        // --- CONVERSIÓN A FORMATO 00:00:00 ---
        int h = tiempoSegundosHoy / 3600;
        int m = (tiempoSegundosHoy % 3600) / 60;
        int s = tiempoSegundosHoy % 60;
        tiempoFormateado = String.format("%02d:%02d:%02d", h, m, s);

        con.close();
    } catch (Exception e) { e.printStackTrace(); }
%>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Perfil - Serena</title>

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

/* PERFIL */
/* checar 
.profile-container {
    text-align: center;
    margin-top: 10px;
}*/
.profile-pic {
    width: 150px;       /* El tamaño del círculo */
    height: 150px;
    border-radius: 50%;
    object-fit: cover;  /* Esto hace que la imagen llene el círculo sin deformarse */
    display: block;
    margin: 0 auto;
    border: 3px solid rgba(255,255,255,0.3); /* Un borde sutil blanco en lugar de gris */
    background-color: #f0f0f0; /* Color de fondo si no hay imagen */
}

/*
.profile-pic{
  width:120px;
  height:120px;
  border-radius:50%;
  object-fit:cover;
  border:3px solid rgba(255,255,255,0.4);
  margin-bottom: 5px;
}
*/
.profile-name{
  margin-top:5px;
  font-size:17px;
  font-weight:700;
}

.profile-company{
  font-size:12px;
  opacity:0.8;
}

/* CONTENIDO */
/* CONTENIDO CON SCROLL INVISIBLE */
.content {
  flex: 1;
  background: rgba(0,0,0,0.25);
  border-radius: 30px 30px 0 0;
  padding: 15px 20px;
  padding-bottom: 80px;
  
  /* Habilitar scroll */
  overflow-y: auto;

  /* Ocultar scrollbar para Chrome, Safari y Opera */
  -webkit-overflow-scrolling: touch; /* Suavidad en móviles */
  scrollbar-width: none;             /* Firefox */
  -ms-overflow-style: none;          /* IE y Edge antiguo */
}

/* Ocultar scrollbar para Chrome, Safari y Edge moderno */
.content::-webkit-scrollbar {
  display: none;
}

.section-title{
  font-size:14px;
  font-weight:700;
  margin:15px 0 10px 0;
}

/* BOTON AUTOEVALUACION */
.self-test{
  background:white;
  color:#3f6ba9;
  text-align:center;
  padding:10px;
  border-radius:12px;
  font-weight:600;
  margin-bottom:13px;
  cursor:pointer;
}

/* --- GRÁFICA ESTILO LÍNEA TRANSPARENTE --- */
.chart-container {
    background: rgba(255, 255, 255, 0); /* transparente */
    border-radius: 15px;
    padding: 10px 5px;
    margin-bottom: 15px;
    color: #fff;
}

.chart-layout {
    display: flex;
    height: 120px;
}

.y-axis {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    font-size: 8px;
    padding-right: 5px;
    text-align: right;
    width: 35px;
    color: #fff; /* etiquetas blancas */
}

.graph-wrapper {
    flex: 1;
    position: relative;
    border-left: 1px solid rgba(255,255,255,0.3);
    border-bottom: 1px solid rgba(255,255,255,0.3);
}

.x-axis {
    display: flex;
    justify-content: space-between;
    padding-left: 40px;
    margin-top: 5px;
    font-size: 8px;
    color: #fff; /* etiquetas blancas */
}

/* SVG Styling acomoda lo de las lineas de la grafica*/
.line-chart {
    width: 100%;
    height: 100%;
}

.chart-line {
    fill: none;
    stroke: #fff; /*línea blanca */
    stroke-width: 3;
    stroke-linejoin: round;
    stroke-linecap: round;
}

.chart-area {
    fill: url(#gradientArea);
}

.chart-point {
    fill: #fff;
    stroke:#3f6ba9;
    stroke-width: 2;
}

/* ESCALA EMOCIONAL*/
.scale{
  display:flex;
  justify-content:space-between;
  font-size:11px;
  margin-bottom:15px;
}

/* NIVELES EMOCIONALES */
.level{
  margin-bottom:12px;
}

.level-header{
  display:flex;
  justify-content:space-between;
  align-items:center;
  font-size:12px;
  margin-bottom:4px;
}

.info{
  width:16px;
  height:16px;
  border-radius:50%;
  background:white;
  color:#3f6ba9;
  font-size:11px;
  display:flex;
  align-items:center;
  justify-content:center;
  cursor:pointer;
  font-weight:bold;
  position:relative; /* agregado */
}

.level-bar{
  width:100%;
  height:8px;
  border-radius:10px;
  background:linear-gradient(90deg,#4c6ef5,#ffa500,#ff3b3b);
  position:relative;
}

.level-dot{
  width:12px;
  height:12px;
  background:white;
  border-radius:50%;
  position:absolute;
  top:50%;
  transform:translate(-50%,-50%);
}

/* MENSAJE DE ALERTA*/
.popup{
  position:absolute;
  top:50%;
  right:calc(100% + 8px); /* a la izquierda del botón */
  transform:translateY(-50%);
  background:white;
  color:black;
  padding:10px;
  border-radius:10px;
  width:180px;
  font-size:11px;
  display:none;
  box-shadow:0 5px 15px rgba(0,0,0,0.3);
  z-index:20;
}

/* STATS */
.stats{
  display:flex;
  justify-content:space-between;
  margin:15px 0;
}

.stat{
  text-align:center;
}

.stat h3{
  margin:0;
  font-size:16px;
}

.stat p{
  margin:0;
  font-size:10px;
  opacity:0.8;
}

/*OPCIONES checar*/
.option{
  background:rgba(255,255,255,0.15);
  padding:10px;
  border-radius:10px;
  margin-bottom:8px;
  font-size: 13px;
  cursor:pointer;
}

/* MENU */
.menu{
position:absolute;
bottom:0;
width:100%;
height:65px;
background:rgba(0, 0, 0, 0.6);
display:flex;
justify-content:space-around;
align-items:center;
font-size:11px;
backdrop-filter: blur(5px);
}

.menu div{
text-align:center;
cursor:pointer;
/*padding:8px 10px;
border-radius:12px;
transition:0.2s;*/
color:rgba(255,255,255,0.7);
}

.menu .active{
  /*background:rgba(255,255,255,0.25);
  padding:6px 10px;
  border-radius:10px;*/
  color:white;
  font-weight: bold;
}
/* checar */
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
    gap: 8px;
    justify-content: center;
    margin-top: 10px;
    /*margin-bottom: 20px;*/
}

.action-btn {
    padding: 6px 10px;
    border: none;
    border-radius: 15px;
    font-size: 10px;
    font-weight: 600;
    cursor: pointer;
    transition: 0.2s;
    /*display: flex;
    align-items: center;
    gap: 5px;*/
}

.btn-change { background: white; color: #3f6ba9; }
.btn-delete { background: rgba(255, 255, 255, 0.2); color: white; }
/*.action-btn:hover { transform: scale(1.05); opacity: 0.9; }
*/
.header{
  padding:45px 20px 15px 20px;
  text-align:center;
}

.header h1 {
    margin: 0 0 10px 0;
    font-size: 20px;
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

.btn-confirmar { background: #ff4757; color: white; }
.btn-cancelar { background: #eee; color: #333; }

html {
    scroll-behavior: smooth;
}

.toast-success {
    position: fixed;
    top: 20px;
    right: 20px;
    background-color: #28a745;
    color: white;
    padding: 15px 25px;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    z-index: 10000;
    animation: fadeInOut 5s forwards;
}

@keyframes fadeInOut {
    0% { opacity: 0; transform: translateY(-20px); }
    10% { opacity: 1; transform: translateY(0); }
    90% { opacity: 1; transform: translateY(0); }
    100% { opacity: 0; transform: translateY(-20px); }
}

</style>
</head>

<body>

<div class="phone-frame">
  <div class="phone">

    <div class="notch"></div>
    
    <div class="header">
        <h1>Mi Perfil</h1>

        <input type="file" id="inputFoto" style="display:none;" accept="image/*" onchange="subirFoto()">

        <div class="profile-name"><%= nombreUsuario %></div>
        <div class="profile-company">Empresa: <%= (nombreEmpresa != null) ? nombreEmpresa : "Particular" %></div>
        <h1> </h1>
        <h1> </h1>

        <img src="<%= fotoPerfil %>" class="profile-pic" id="profilePic">

        <div class="image-actions">
            <button class="action-btn btn-change" onclick="abrirGaleria()">📷 Cambiar</button>
            <button class="action-btn btn-delete" onclick="eliminarFoto()">🗑️ Eliminar</button>
        </div>
    </div>
    
    <div class="content">
      <div class="self-test" onclick="abrirModalTest()">Realizar autoevaluación de hoy</div>

        <div id="modalTest" class="modal-overlay" style="display:none; overflow-y: auto;">
    <div class="modal-content" style="width: 85%; max-height: 80vh; overflow-y: auto;">
        <h3>Evaluación de Bienestar</h3>
        <p>Responde con sinceridad. Tus respuestas nos ayudan a cuidarte.</p>
        
        <form id="testForm">
            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">1. ¿Con qué frecuencia te cuesta desconectarte del trabajo al terminar el día?</p>
                <select name="p1" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">Nunca</option>
                    <option value="10">A veces</option>
                    <option value="25">Frecuentemente</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">2. ¿Te has sentido irritable o con poca paciencia últimamente?</p>
                <select name="p2" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">Para nada</option>
                    <option value="15">Un poco</option>
                    <option value="25">Mucho</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">3. ¿Has tenido dificultades para conciliar el sueño o te despiertas cansado?</p>
                <select name="p3" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">Casi nunca</option>
                    <option value="15">A veces</option>
                    <option value="25">Casi siempre</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">4. ¿Sientes tensión muscular excesiva (cuello, espalda o mandíbula)?</p>
                <select name="p4" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">No, me siento relajado/a</option>
                    <option value="10">Algo de tensión</option>
                    <option value="25">Mucha tensión</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">5. ¿Has perdido el interés por actividades que antes disfrutabas?</p>
                <select name="p5" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">No, sigo disfrutándolas</option>
                    <option value="20">Un poco</option>
                    <option value="30">Sí, bastante</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">6. ¿Sientes que tienes demasiadas responsabilidades y no puedes con todas?</p>
                <select name="p6" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">Puedo manejarlas bien</option>
                    <option value="15">A veces me abrumo</option>
                    <option value="25">Sí, me siento sobrepasado/a</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">7. ¿Te sientes inquieto/a, como si no pudieras quedarte sentado/a tranquilo/a?</p>
                <select name="p7" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">Para nada</option>
                    <option value="15">Ocasionalmente</option>
                    <option value="25">Constantemente</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">8. ¿Te ha resultado difícil concentrarte en tus tareas hoy?</p>
                <select name="p8" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">Me concentré bien</option>
                    <option value="10">Me distraje un poco</option>
                    <option value="25">Fue muy difícil concentrarme</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">9. ¿Has experimentado sentimientos de tristeza o vacío hoy?</p>
                <select name="p9" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">No</option>
                    <option value="15">Ligeramente</option>
                    <option value="30">Sí, bastante</option>
                </select>
            </div>

            <div class="pregunta" style="text-align: left; margin-bottom: 15px;">
                <p style="font-size: 12px; font-weight: bold;">10. ¿Te sientes optimista respecto a tu futuro cercano?</p>
                <select name="p10" style="width: 100%; padding: 5px; border-radius: 5px;">
                    <option value="0">Muy optimista</option>
                    <option value="15">Algo inseguro/a</option>
                    <option value="30">Poco optimista</option>
                </select>
            </div>
        </form>

        <div class="modal-buttons">
            <button class="btn-confirmar" style="background: #3f6ba9;" onclick="procesarTest()">Finalizar Test</button>
            <button type="button" onclick="confirmarSalida()">Salir</button>
        </div>
    </div>
</div>
      <div id="seccionGrafica" class="section-title">Estadísticas de bienestar mensual</div>

      <div class="chart-container">
          <div class="chart-layout">
              <div class="y-axis">
                  <span>100%😁</span>
                  <span>80%😃</span>
                  <span>60%😊</span>
                  <span>40%😐</span>
                  <span>20%😕</span>
                  <span>0%😭</span>
              </div>
              <div class="graph-wrapper">
                  <svg class="line-chart" viewBox="0 0 100 100" preserveAspectRatio="none">
                      <defs>
                          <linearGradient id="gradientArea" x1="0" y1="0" x2="0" y2="1">
                              <stop offset="0%" stop-color="#fff" stop-opacity="0.3"/>
                              <stop offset="100%" stop-color="#fff" stop-opacity="0"/>
                          </linearGradient>
                      </defs>
                      <polyline points="0,100 <%= puntosGrafica %> 100,100" fill="url(#gradientArea)" stroke="none" />
                      <polyline class="chart-line" points="<%= puntosGrafica %>" />
                      
                      <%-- Un pequeño círculo en el último punto (el de hoy) --%>
                      <% 
                         if(!listaPorcentajes.isEmpty()) { 
                           int ultimoY = 100 - listaPorcentajes.get(listaPorcentajes.size()-1);
                      %>
                        <circle class="chart-point" cx="100" cy="<%= ultimoY %>" r="3" />
                      <% } %>
                  </svg>
              </div>
          </div>
          <div class="x-axis">
              <%-- Estas etiquetas representan el avance del mes --%>
              <span>Día 1</span>
              <span>7</span>
              <span>14</span>
              <span>21</span>
              <span>Hoy</span>
          </div>
      </div>

      <div id="seccionNiveles" class="section-title">Niveles emocionales</div>

      <div class="level">
        <div class="level-header">
          <span>Ansiedad</span>
          <div class="info" onclick="mostrar('ansiedad')">!</div>
        </div>
        <div class="level-bar">
          <div class="level-dot" style="left:<%= nivelAnsiedad %>%"></div>
        </div>
      </div>

      <div class="level">
        <div class="level-header">
          <span>Estrés</span>
          <div class="info" onclick="mostrar('estres')">!</div>
        </div>
        <div class="level-bar">
          <div class="level-dot" style="left:<%= nivelEstres %>%"></div>
        </div>
      </div>

      <div class="level">
        <div class="level-header">
          <span>Depresión</span>
          <div class="info" onclick="mostrar('depresion')">!</div>
        </div>
        <div class="level-bar">
          <div class="level-dot" style="left:<%= nivelDepresion %>%"></div>
        </div>
      </div>

      <div class="section-title">Uso de la app</div>

      <div class="stats">
        <div class="stat">
          <h3><%= racha %> 🔥</h3>
          <p>Racha</p>
        </div>
        <div class="stat">
          <h3><%= tiempoFormateado %></h3>
          <p>Tiempo de uso hoy</p>
        </div>
        <div class="stat">
          <h3>4</h3>
          <p>Sesiones</p>
        </div>
      </div>

      <div class="section-title">Opciones</div>
        <div class="option" onclick="abrirModalEditar()">Editar perfil</div>
        <div class="option" onclick="abrirModalCerrar()">Cerrar sesión</div>

    </div>

    <div class="popup" id="popup"></div>

    <div class="menu">
      <div onclick="location.href='homeTrabajador.jsp';">🏠<br>Inicio</div>
      <div onclick="location.href='sueno.jsp';">🌙<br>Sueño</div>
      <div onclick="location.href='meditar.jsp';">🧘<br>Meditar</div>
      <div onclick="location.href='audios.jsp';">🎵<br>Audios</div>
      <div onclick="location.href='${pageContext.request.contextPath}/ListarPsicologosServlet';">💬<br>Chat</div>
      <div class="active">👤<br>Perfil</div>
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
        <h3>Editar Perfil</h3>
        <input type="text" id="editNombre" value="<%= nombreUsuario %>" 
               style="width: 90%; padding: 10px; margin-bottom: 15px; border-radius: 8px; border: 1px solid #ccc;">
        
        <p style="margin-bottom: 5px;">Cambiar foto:</p>
        <button class="action-btn btn-change" onclick="document.getElementById('inputFotoEditar').click()" style="margin-bottom: 15px;">
            📁 Seleccionar Imagen
        </button>
        <input type="file" id="inputFotoEditar" style="display:none;" accept="image/*" onchange="previsualizarEdicion()">
        <img id="previewEdit" src="<%= fotoPerfil %>" style="width: 60px; height: 60px; border-radius: 50%; object-fit: cover; display: block; margin: 0 auto 15px;">

        <div class="modal-buttons">
            <button class="btn-confirmar" style="background: #3f6ba9;" onclick="guardarCambiosPerfil()">Guardar Cambios</button>
            <button class="btn-cancelar" onclick="cerrarModalGeneral('modalEditarPerfil')">Cancelar</button>
        </div>
    </div>
</div>

<div id="modalCerrarSesion" class="modal-overlay">
    <div class="modal-content">
        <h3 style="color: #ff4757;">⚠️ Zona de Peligro</h3>
        <p>Si eliminas tu cuenta, perderás todo tu avance en <b>Serena</b> de forma permanente.</p>
        <div class="modal-buttons">
            <button class="btn-confirmar" onclick="confirmarBorrarCuenta()">Eliminar Cuenta Definitivamente</button>
            <button class="btn-cancelar" onclick="cerrarModalGeneral('modalCerrarSesion')">Regresar</button>
        </div>
    </div>
</div>
    
  </div>
</div>

<script>
// --- VARIABLES GLOBALES ---
let fotoBase64Nueva = ""; 

// --- GESTIÓN DE MODALES GENERAL ---
function cerrarModalGeneral(id) {
    const modal = document.getElementById(id);
    if(modal) modal.style.display = 'none';
}

function abrirModalGeneral(id) {
    const modal = document.getElementById(id);
    if(modal) modal.style.display = 'flex';
}

// --- FOTO DE PERFIL (ACCIONES RÁPIDAS) ---
function abrirGaleria() {
    document.getElementById('inputFoto').click();
}

function subirFoto() {
    const input = document.getElementById('inputFoto');
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const base64Image = e.target.result;
            enviarFormularioDinamico({ accion: 'foto', valor: base64Image });
        };
        reader.readAsDataURL(input.files[0]);
    }
}

function eliminarFoto() {
    abrirModalGeneral('modalEliminar');
}

function confirmarEliminacion() {
    window.location.href = "perfil.jsp?accion=eliminarFoto";
}

// --- EDITAR PERFIL (MODAL COMBINADO) ---
function abrirModalEditar() {
    abrirModalGeneral('modalEditarPerfil');
}

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
    const nuevoNombre = document.getElementById('editNombre').value;
    if (nuevoNombre.trim() === "") {
        alert("El nombre no puede estar vacío");
        return;
    }
    enviarFormularioDinamico({ 
        accion: 'editarPerfil', 
        nombre: nuevoNombre, 
        foto: fotoBase64Nueva 
    });
}

// --- CERRAR SESIÓN / BORRAR CUENTA ---
function abrirModalCerrar() {
    abrirModalGeneral('modalCerrarSesion');
}

function confirmarBorrarCuenta() {
    window.location.href = "perfil.jsp?accion=borrarCuenta";
}

// --- AUTOEVALUACIÓN (TEST) ---
function abrirModalTest() {
    abrirModalGeneral('modalTest');
}

function procesarTest() {
    const form = document.getElementById('testForm');
    if (!form) return;

    const formData = new FormData(form);
    const getVal = (name) => parseInt(formData.get(name)) || 0;

    // Lógica de cálculo basada en tus preguntas
    let ans = Math.min(getVal('p1') + getVal('p7') + getVal('p8'), 100);
    let est = Math.min(getVal('p2') + getVal('p4') + getVal('p6'), 100);
    let dep = Math.min(getVal('p3') + getVal('p5') + getVal('p9') + getVal('p10'), 100);

    enviarFormularioDinamico({ 
        accion: 'guardarTest', 
        ansiedad: ans, 
        estres: est, 
        depresion: dep 
    });

    cerrarModalGeneral('modalTest');
    mostrarToastExitosa(); 
}

function confirmarSalida() {
    if (confirm("¿Seguro que quieres salir? No se guardarán los cambios del test.")) {
        cerrarModalGeneral('modalTest');
    }
}

function mostrarToastExitosa() {
    const toast = document.createElement('div');
    toast.className = 'toast-success';
    toast.innerText = 'Test finalizado exitosamente';
    document.body.appendChild(toast);
    setTimeout(() => { toast.remove(); }, 5000);
}

// --- TOOLTIPS DE BIENESTAR (INFO) ---
function mostrar(tipo) {
    const niveles = {
        ansiedad: <%= nivelAnsiedad %>,
        estres: <%= nivelEstres %>,
        depresion: <%= nivelDepresion %>
    };

    const valorActual = niveles[tipo];
    const mensajes = {
        ansiedad: {
            bajo: "Te sientes tranquilo/a. Sigue manteniendo este equilibrio.",
            medio: "Sientes algo de inquietud. Te recomendamos 'Respiración Guiada'.",
            alto: "Nivel alto. Por favor, contacta a un profesional en el Chat."
        },
        estres: {
            bajo: "Tu carga es manejable. ¡Buen trabajo!",
            medio: "Presión detectada. Prueba 'Sonidos de Naturaleza'.",
            alto: "Agotamiento alto. Considera una sesión de 'Mindfulness'."
        },
        depresion: {
            bajo: "Tu estado de ánimo es estable.",
            medio: "Ánimo bajo. Escuchar 'Música Motivadora' podría ayudarte.",
            alto: "Sentimientos intensos. Usa el botón de 'Chat' para hablar con nosotros."
        }
    };

    let rango = valorActual > 66 ? "alto" : (valorActual > 33 ? "medio" : "bajo");
    let texto = mensajes[tipo][rango];

    // Limpiar popups anteriores
    document.querySelectorAll('.popup').forEach(p => p.remove());

    const popup = document.createElement('div');
    popup.className = 'popup';
    popup.innerText = texto;
    popup.style.display = "block";

    event.currentTarget.appendChild(popup);

    setTimeout(() => { if (popup) popup.remove(); }, 5000);
}

// --- UTILIDAD: ENVÍO DE FORMULARIOS POST ---
function enviarFormularioDinamico(params) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = 'perfil.jsp';

    for (const key in params) {
        if (params.hasOwnProperty(key)) {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = key;
            input.value = params[key];
            form.appendChild(input);
        }
    }
    document.body.appendChild(form);
    form.submit();
}
</script>


</body>
</html>