<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");

    Integer idEmpresa  = (Integer) session.getAttribute("idEmpresa");
    String  tipoUsuario = (String) session.getAttribute("tipoUsuario");

    if (idEmpresa == null || !"empresa".equalsIgnoreCase(tipoUsuario)) {
        response.sendRedirect("login.html");
        return;
    }

    String DB_URL  = System.getenv().getOrDefault("DB_URL",
        "jdbc:mysql://roundhouse.proxy.rlwy.net:45224/railway?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8");
    String DB_USER = System.getenv().getOrDefault("DB_USER", "root");
    String DB_PASS = System.getenv().getOrDefault("DB_PASS", "vYBluCJLeLEqOKtswQfDAzlRkyxRVAKF");

    String nombreEmpresa      = "Mi Empresa";
    int    totalEmpleados     = 0;
    double estresPromedio     = 0;   // escala 0-10 para mostrar
    double desempenioPromedio = 0;   // escala 0-10 para mostrar
    int    bajasRecientes     = 0;

    List<Map<String,Object>> datosGrafica = new ArrayList<>();
    List<String> alertas = new ArrayList<>();
    List<Map<String,String>> reportes = new ArrayList<>();
    String dbError = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // 1. Nombre empresa
        PreparedStatement ps = con.prepareStatement(
            "SELECT nombre FROM empresa WHERE id_empresa = ?");
        ps.setInt(1, idEmpresa);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) nombreEmpresa = rs.getString("nombre");
        rs.close(); ps.close();

        // 2. Total empleados activos (tipo_usuario = 'empleado' en tabla usuario)
        ps = con.prepareStatement(
            "SELECT COUNT(*) FROM usuario WHERE id_Empresa = ? AND tipo_usuario = 'empleado'");
        ps.setInt(1, idEmpresa);
        rs = ps.executeQuery();
        if (rs.next()) totalEmpleados = rs.getInt(1);
        rs.close(); ps.close();

        // ── FIX 1: Estrés y desempeño promedio ────────────────────────────────────
        // El servlet guarda estres_promedio en escala 0-100 (multiplica *10 antes de insertar)
        // y usa desempeño_promedio para guardar ansiedadPromedio (bug del servlet original).
        // Leemos ambos y dividimos /10 UNA SOLA VEZ para escala 0-10.
        ps = con.prepareStatement(
            "SELECT estres_promedio, desempeño_promedio FROM reporte_quincenal " +
            "WHERE id_empresa = ? AND recomendaciones IS NOT NULL AND recomendaciones != '' " +
            "ORDER BY fecha DESC LIMIT 1");
        ps.setInt(1, idEmpresa);
        rs = ps.executeQuery();
        if (rs.next()) {
            // Ambos vienen en escala 0-100 → dividir entre 10 para mostrar 0-10
            int rawEstres    = rs.getInt("estres_promedio");
            int rawDesempenio= rs.getInt("desempeño_promedio");
            estresPromedio     = rawEstres     / 10.0;
            desempenioPromedio = rawDesempenio / 10.0;
        }
        rs.close(); ps.close();

        // ── FIX 2: Bajas ───────────────────────────────────────────────────────────
        // La baja definitiva ELIMINA al usuario → ya no hay registro que contar.
        // Contamos registros en reporte_quincenal que tengan la cantidad de bajas registrada
        // ... pero como no hay tabla de historial de bajas, usamos una alternativa:
        // Contar entradas en empleado con activo=0 vinculadas a esta empresa (si la tabla existe).
        // Si no, usar el total de bajas registradas en los reportes.
        // Estrategia robusta: intentar empleado.activo=0, si falla usar 0.
        try {
            ps = con.prepareStatement(
                "SELECT COUNT(*) FROM empleado e " +
                "JOIN usuario u ON e.id_usuario = u.id_usuario " +
                "WHERE u.id_Empresa = ? AND e.activo = 0");
            ps.setInt(1, idEmpresa);
            rs = ps.executeQuery();
            if (rs.next()) bajasRecientes = rs.getInt(1);
            rs.close(); ps.close();
        } catch (Exception eBajas) {
            // Si la tabla empleado no tiene columna activo o no existe, calcular
            // como diferencia entre primer reporte y total actual
            try {
                ps = con.prepareStatement(
                    "SELECT (SELECT total_pacientes FROM reporte_quincenal " +
                    "        WHERE id_empresa = ? AND total_pacientes IS NOT NULL " +
                    "        ORDER BY fecha ASC LIMIT 1) - " +
                    "(SELECT COUNT(*) FROM usuario WHERE id_Empresa = ? AND tipo_usuario='empleado') AS bajas");
                ps.setInt(1, idEmpresa);
                ps.setInt(2, idEmpresa);
                rs = ps.executeQuery();
                if (rs.next()) {
                    int b = rs.getInt("bajas");
                    bajasRecientes = b > 0 ? b : 0;
                }
                rs.close(); ps.close();
            } catch (Exception ignored2) {}
        }

        // 5. Datos para la gráfica (últimos 6 reportes reales con recomendaciones)
        ps = con.prepareStatement(
            "SELECT rq.fecha, rq.estres_promedio, rq.desempeño_promedio, " +
            "  (SELECT COUNT(*) FROM usuario u2 WHERE u2.id_Empresa = ? AND u2.tipo_usuario='empleado') AS total_emp " +
            "FROM reporte_quincenal rq " +
            "WHERE rq.id_empresa = ? AND rq.recomendaciones IS NOT NULL AND rq.recomendaciones != '' " +
            "ORDER BY rq.fecha ASC LIMIT 6");
        ps.setInt(1, idEmpresa);
        ps.setInt(2, idEmpresa);
        rs = ps.executeQuery();
        while (rs.next()) {
            Map<String,Object> punto = new LinkedHashMap<>();
            String fechaStr = rs.getString("fecha");
            String label = fechaStr != null ? fechaStr.substring(5, 10).replace("-", "/") : "—";
            // Valores crudos 0-100 para la gráfica (ya normaliza en JS)
            punto.put("label",      label);
            punto.put("empleados",  rs.getInt("total_emp"));
            punto.put("estres",     rs.getInt("estres_promedio"));
            punto.put("desempenio", rs.getInt("desempeño_promedio"));
            punto.put("bajas",      bajasRecientes);
            datosGrafica.add(punto);
        }
        rs.close(); ps.close();

        // 6. Alertas automáticas
        if (estresPromedio > 7.0) {
            alertas.add("⚠️ Nivel de estrés elevado (" + String.format("%.1f", estresPromedio) + "/10). Se recomienda intervención psicológica.");
        } else if (estresPromedio > 4.0) {
            alertas.add("🟡 Estrés moderado detectado (" + String.format("%.1f", estresPromedio) + "/10). Monitorear evolución.");
        } else if (estresPromedio > 0) {
            alertas.add("✅ Niveles de estrés dentro de rangos saludables (" + String.format("%.1f", estresPromedio) + "/10).");
        }
        if (desempenioPromedio > 0 && desempenioPromedio < 6.0) {
            alertas.add("⚠️ Desempeño promedio bajo (" + String.format("%.1f", desempenioPromedio) + "/10). Revisar carga de trabajo.");
        } else if (desempenioPromedio >= 8.0) {
            alertas.add("✅ Desempeño del equipo en nivel óptimo (" + String.format("%.1f", desempenioPromedio) + "/10).");
        }
        if (bajasRecientes > 0) {
            alertas.add("📉 " + bajasRecientes + " empleado" + (bajasRecientes > 1 ? "s" : "") +
                        " inactivo" + (bajasRecientes > 1 ? "s" : "") + " registrado" + (bajasRecientes > 1 ? "s" : "") + ".");
        }
        if (alertas.isEmpty()) {
            alertas.add("ℹ️ Sin alertas activas. Todo en orden.");
        }

        // 7. Historial de reportes — incluye id_reporte y quincena guardada en observaciones
        ps = con.prepareStatement(
            "SELECT rq.id_reporte, u.nombre AS psicologo, " +
            "DATE_FORMAT(rq.fecha,'%d/%m/%Y') AS fecha_fmt, " +
            "rq.observaciones " +
            "FROM reporte_quincenal rq " +
            "JOIN psicologo p ON rq.id_psicologo = p.id_psicologo " +
            "JOIN usuario u ON p.id_usuario = u.id_usuario " +
            "WHERE rq.id_empresa = ? " +
            "AND rq.recomendaciones IS NOT NULL AND rq.recomendaciones != '' " +
            "ORDER BY rq.fecha DESC LIMIT 10");
        ps.setInt(1, idEmpresa);
        rs = ps.executeQuery();
        int numReporte = 1;
        while (rs.next()) {
            Map<String,String> rep = new LinkedHashMap<>();
            rep.put("id",         rs.getString("id_reporte"));
            rep.put("psicologo",  rs.getString("psicologo") != null ? rs.getString("psicologo") : "Psicólogo");
            rep.put("fecha",      rs.getString("fecha_fmt")  != null ? rs.getString("fecha_fmt")  : "—");
            // Extraer el rango de quincena guardado en observaciones
            String obs = rs.getString("observaciones");
            String quincena = "—";
            if (obs != null && obs.contains("Quincena:")) {
                quincena = obs.replace("Reporte quincenal generado. Quincena:", "").replace("Reporte quincenal generado. Quincena: ","").trim();
            }
            rep.put("quincena",   quincena);
            rep.put("num",        String.valueOf(numReporte++));
            reportes.add(rep);
        }
        rs.close(); ps.close();
        con.close();

    } catch (Exception e) {
        e.printStackTrace();
        dbError = "Error al conectar con la base de datos: " + e.getMessage();
    }

    // Preparar datos JS
    StringBuilder jsLabels    = new StringBuilder("[");
    StringBuilder jsEmpleados = new StringBuilder("[");
    StringBuilder jsEstres    = new StringBuilder("[");
    StringBuilder jsDesempenio= new StringBuilder("[");
    StringBuilder jsBajas     = new StringBuilder("[");

    if (datosGrafica.isEmpty()) {
        String[] meses = {"Ene","Feb","Mar","Abr","May","Jun"};
        for (int i = 0; i < 6; i++) {
            if (i > 0) { jsLabels.append(","); jsEmpleados.append(","); jsEstres.append(","); jsDesempenio.append(","); jsBajas.append(","); }
            jsLabels.append("\"").append(meses[i]).append("\"");
            jsEmpleados.append(totalEmpleados);
            jsEstres.append(0);
            jsDesempenio.append(0);
            jsBajas.append(0);
        }
    } else {
        for (int i = 0; i < datosGrafica.size(); i++) {
            Map<String,Object> p = datosGrafica.get(i);
            if (i > 0) { jsLabels.append(","); jsEmpleados.append(","); jsEstres.append(","); jsDesempenio.append(","); jsBajas.append(","); }
            jsLabels.append("\"").append(p.get("label")).append("\"");
            jsEmpleados.append(p.get("empleados"));
            jsEstres.append(p.get("estres"));
            jsDesempenio.append(p.get("desempenio"));
            jsBajas.append(p.get("bajas"));
        }
    }
    jsLabels.append("]"); jsEmpleados.append("]"); jsEstres.append("]"); jsDesempenio.append("]"); jsBajas.append("]");

    // FIX 1: mostrar valores correctos (escala 0-10)
    String estresDisplay     = estresPromedio     > 0 ? String.format("%.1f", estresPromedio)     + "/10" : "—";
    String desempenioDisplay = desempenioPromedio > 0 ? String.format("%.1f", desempenioPromedio) + "/10" : "—";
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Home RRHH - Serena</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
<style>
body{
  margin:0;height:100vh;display:flex;justify-content:center;
  align-items:center;background:#e6e6e6;font-family:'Plus Jakarta Sans', sans-serif;
}
.phone-frame{
  width:380px;height:760px;background:black;border-radius:50px;padding:15px;
  box-shadow:0 30px 60px rgba(0,0,0,0.4);display:flex;justify-content:center;align-items:center;
}
.phone{
  width:340px;height:680px;
  background:linear-gradient(180deg,#6aa3d6,#3f6ba9);
  border-radius:40px;overflow:hidden;color:white;position:relative;display:flex;flex-direction:column;
}
.notch{
  width:120px;height:25px;background:black;border-radius:0 0 20px 20px;
  position:absolute;top:0;left:50%;transform:translateX(-50%);z-index:10;
}
.header{
  padding:40px 25px 18px 25px;text-align:center;
  background:rgba(0,0,0,0.2);border-bottom:1px solid rgba(255,255,255,0.2);
}
.header h1{margin:0;font-size:20px;font-weight:bold;}
.header p{margin:3px 0 0 0;font-size:12px;opacity:0.8;}
.content{flex:1;padding:10px 0 80px 0;overflow-y:auto;scrollbar-width:none;}
.content::-webkit-scrollbar { display:none; }
.section-title{font-size:13px;font-weight:700;margin:12px 15px 8px 15px;}
.metrics-row{display:flex;gap:6px;padding:0 15px;margin-bottom:12px;}
.metric-card{
  flex:1;background:white;color:#333;border-radius:12px;
  padding:8px 4px;text-align:center;display:flex;flex-direction:column;justify-content:center;
}
.metric-card h3{margin:0;font-size:14px;font-weight:700;color:#3f6ba9;}
.metric-card p{margin:3px 0 0 0;font-size:9px;opacity:0.65;line-height:1.2;}
.chart-container{
  background:rgba(255,255,255,0.12);border-radius:15px;
  margin:0 15px 12px 15px;padding:12px 10px 8px 10px;
}
.chart-title{font-size:11px;font-weight:700;opacity:0.8;margin-bottom:8px;}
.canvas-wrap{position:relative;width:100%;height:100px;}
canvas#grafica{width:100%;height:100%;display:block;}
.chart-tooltip{
  position:absolute;background:rgba(0,0,0,0.75);color:white;
  padding:4px 8px;border-radius:6px;font-size:10px;pointer-events:none;
  opacity:0;transition:opacity 0.2s;white-space:nowrap;z-index:20;
}
.legend{display:flex;justify-content:space-around;font-size:9px;margin-top:6px;}
.legend span{display:flex;align-items:center;gap:3px;}
.legend-dot{width:8px;height:8px;border-radius:2px;flex-shrink:0;}
.alert-card{border-radius:12px;padding:9px 12px;margin:6px 15px;font-size:11px;font-weight:600;line-height:1.4;}
.alert-warning { background:#fff3cd; color:#856404; }
.alert-danger   { background:#f8d7da; color:#721c24; }
.alert-success  { background:#d1f2eb; color:#145a32; }
.alert-info     { background:#d6eaf8; color:#1a5276; }
.report-card{
  background:rgba(255,255,255,0.15);border-radius:13px;padding:10px 12px;
  margin:6px 15px;display:flex;align-items:center;gap:10px;cursor:pointer;
  transition:background 0.2s;text-decoration:none;color:white;
}
.report-card:hover{ background:rgba(255,255,255,0.25); }
.report-icon{
  width:34px;height:34px;background:rgba(255,255,255,0.2);
  border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;
}
.report-info{ flex:1; }
.report-info h4{margin:0;font-size:12px;font-weight:700;}
.report-info p {margin:2px 0 0;font-size:10px;opacity:0.75;}
.report-quincena{font-size:9px;opacity:0.6;margin-top:1px;}
.report-badge{
  font-size:9px;font-weight:700;background:rgba(39,174,96,0.3);color:#a8f0c6;
  border:1px solid rgba(39,174,96,0.4);padding:2px 7px;border-radius:20px;white-space:nowrap;
}
.empty-state{text-align:center;padding:20px;opacity:0.65;font-size:12px;}
.db-error{
  margin:8px 15px;padding:8px 12px;background:rgba(255,77,77,0.25);
  border-radius:10px;font-size:11px;border:1px solid rgba(255,77,77,0.4);
}
.menu{
  position:absolute;bottom:0;width:100%;height:70px;background:rgba(0,0,0,0.5);
  display:flex;justify-content:space-around;align-items:center;font-size:12px;backdrop-filter:blur(10px);
}
.menu div{
  text-align:center;cursor:pointer;padding:8px 10px;
  border-radius:12px;transition:0.2s;color:rgba(255,255,255,0.8);
}
.menu .active{background:rgba(255,255,255,0.25);transform:scale(1.05);font-weight:bold;color:white;}
</style>
</head>
<body>

<div class="phone-frame">
  <div class="phone">
    <div class="notch"></div>

    <div class="header">
      <h1>&#161;Bienvenido!</h1>
      <p><%= nombreEmpresa %> &middot; Resumen general de tu equipo</p>
    </div>

    <div class="content">

      <% if (!dbError.isEmpty()) { %>
      <div class="db-error">&#9888;&#65039; <%= dbError %></div>
      <% } %>

      <!-- MÉTRICAS -->
      <div class="section-title">M&#233;tricas clave</div>
      <div class="metrics-row">
        <div class="metric-card">
          <h3><%= totalEmpleados %></h3>
          <p>Empleados</p>
        </div>
        <div class="metric-card">
          <!-- FIX 1: ahora muestra valor real en escala 0-10 -->
          <h3><%= estresDisplay %></h3>
          <p>Estr&#233;s prom.</p>
        </div>
        <div class="metric-card">
          <!-- FIX 1: desempeño también real -->
          <h3><%= desempenioDisplay %></h3>
          <p>Ansiedad prom.</p>
        </div>
        <div class="metric-card">
          <!-- FIX 2: bajas reales -->
          <h3 style="color:<%= bajasRecientes > 0 ? "#e74c3c" : "#27ae60" %>;"><%= bajasRecientes %></h3>
          <p>Bajas</p>
        </div>
      </div>

      <!-- GRÁFICA -->
      <div class="chart-container">
        <div class="chart-title">&#128202; Evoluci&#243;n &#250;ltimos reportes</div>
        <div class="canvas-wrap">
          <canvas id="grafica"></canvas>
          <div class="chart-tooltip" id="chartTooltip"></div>
        </div>
        <div class="legend">
          <span><div class="legend-dot" style="background:#ffffff;"></div>Empleados</span>
          <span><div class="legend-dot" style="background:#ff9f43;"></div>Estr&#233;s</span>
          <span><div class="legend-dot" style="background:#54a0ff;"></div>Ansiedad</span>
          <span><div class="legend-dot" style="background:#ff6b6b;"></div>Bajas</span>
        </div>
      </div>

      <!-- ALERTAS -->
      <div class="section-title">Alertas recientes</div>
      <% for (String alerta : alertas) {
           String cls = "alert-info";
           if (alerta.startsWith("⚠️"))  cls = "alert-danger";
           else if (alerta.startsWith("🟡")) cls = "alert-warning";
           else if (alerta.startsWith("✅")) cls = "alert-success";
           else if (alerta.startsWith("📉")) cls = "alert-warning";
      %>
      <div class="alert-card <%= cls %>"><%= alerta %></div>
      <% } %>

      <!-- HISTORIAL REPORTES -->
      <div class="section-title">Historial de reportes</div>
      <% if (reportes.isEmpty()) { %>
        <div class="empty-state">
          &#128194;<br>
          A&#250;n no hay reportes generados para tu empresa.
        </div>
      <% } else {
           for (Map<String,String> rep : reportes) { %>
        <!-- FIX 3: cada reporte usa su propio id_reporte para abrir el PDF correcto -->
        <a class="report-card"
           href="${pageContext.request.contextPath}/ReporteServlet?accion=verPDF&id=<%= rep.get("id") %>"
           target="_blank">
          <div class="report-icon">&#128196;</div>
          <div class="report-info">
            <h4>Reporte Quincenal #<%= rep.get("num") %></h4>
            <p>Dr. <%= rep.get("psicologo") %> &middot; <%= rep.get("fecha") %></p>
            <% if (!"—".equals(rep.get("quincena"))) { %>
            <p class="report-quincena">&#128197; Quincena: <%= rep.get("quincena") %></p>
            <% } %>
          </div>
          <div class="report-badge">&#10003; PDF</div>
        </a>
      <% } } %>

    </div><!-- /content -->

    <div class="menu">
      <div class="active">&#127968;<br>Home</div>
      <div onclick="location.href='infoEmpleados.jsp';">&#128100;&#8205;&#128188;<br>Empleados</div>
      <div onclick="location.href='perfilEmpresa.jsp';">&#128100;<br>Perfil</div>
    </div>

  </div>
</div>

<script>
var labels      = <%= jsLabels %>;
var dEmpleados  = <%= jsEmpleados %>;
var dEstres     = <%= jsEstres %>;
var dDesempenio = <%= jsDesempenio %>;
var dBajas      = <%= jsBajas %>;

var canvas  = document.getElementById('grafica');
var tooltip = document.getElementById('chartTooltip');

function dibujarGrafica() {
    var wrap = canvas.parentElement;
    var W = wrap.offsetWidth  || 260;
    var H = wrap.offsetHeight || 100;
    canvas.width  = W;
    canvas.height = H;

    var ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, W, H);

    var n = labels.length;
    if (n === 0) return;

    var padL = 8, padR = 8, padT = 10, padB = 18;
    var gW = W - padL - padR;
    var gH = H - padT - padB;

    ctx.strokeStyle = 'rgba(255,255,255,0.2)';
    ctx.lineWidth   = 0.5;
    ctx.beginPath();
    ctx.moveTo(padL, padT); ctx.lineTo(padL, padT + gH);
    ctx.lineTo(padL + gW, padT + gH);
    ctx.stroke();

    [25, 50, 75].forEach(function(pct) {
        var y = padT + gH - (pct / 100) * gH;
        ctx.beginPath();
        ctx.setLineDash([2, 3]);
        ctx.moveTo(padL, y); ctx.lineTo(padL + gW, y);
        ctx.stroke();
        ctx.setLineDash([]);
    });

    ctx.fillStyle = 'rgba(255,255,255,0.6)';
    ctx.font      = '7px Plus Jakarta Sans, sans-serif';
    ctx.textAlign = 'center';
    labels.forEach(function(lbl, i) {
        var x = padL + (i / (n > 1 ? n - 1 : 1)) * gW;
        ctx.fillText(lbl, x, H - 3);
    });

    var maxEmp = Math.max.apply(null, dEmpleados.concat([1]));

    function normEmp(v)  { return 1 - (v / (maxEmp * 1.3)); }
    function normEst(v)  { return 1 - (v / 100); }
    function normDes(v)  { return 1 - (v / 100); }
    function normBaj(v)  {
        var maxB = Math.max.apply(null, dBajas.concat([1]));
        return 1 - (v / (maxB * 1.5 + 0.001));
    }

    function dibujarSerie(datos, normFn, color, dash) {
        if (datos.every(function(v) { return v === 0; })) return;
        ctx.beginPath();
        ctx.setLineDash(dash || []);
        ctx.strokeStyle = color;
        ctx.lineWidth   = 1.8;
        ctx.lineJoin    = 'round';
        ctx.lineCap     = 'round';
        datos.forEach(function(v, i) {
            var x = padL + (i / (n > 1 ? n - 1 : 1)) * gW;
            var y = padT + normFn(v) * gH;
            if (i === 0) ctx.moveTo(x, y);
            else         ctx.lineTo(x, y);
        });
        ctx.stroke();
        ctx.setLineDash([]);
        datos.forEach(function(v, i) {
            var x = padL + (i / (n > 1 ? n - 1 : 1)) * gW;
            var y = padT + normFn(v) * gH;
            ctx.beginPath();
            ctx.arc(x, y, 2.5, 0, Math.PI * 2);
            ctx.fillStyle = color;
            ctx.fill();
            ctx.strokeStyle = 'rgba(0,0,0,0.3)';
            ctx.lineWidth   = 0.5;
            ctx.stroke();
        });
    }

    dibujarSerie(dEmpleados,  normEmp, '#ffffff');
    dibujarSerie(dEstres,     normEst, '#ff9f43');
    dibujarSerie(dDesempenio, normDes, '#54a0ff');
    dibujarSerie(dBajas,      normBaj, '#ff6b6b', [3,3]);

    canvas._puntos = labels.map(function(lbl, i) {
        return {
            label:      lbl,
            x:          padL + (i / (n > 1 ? n - 1 : 1)) * gW,
            empleados:  dEmpleados[i],
            estres:     (dEstres[i] / 10).toFixed(1),
            desempenio: (dDesempenio[i] / 10).toFixed(1),
            bajas:      dBajas[i]
        };
    });
}

dibujarGrafica();
window.addEventListener('resize', dibujarGrafica);

canvas.addEventListener('mousemove', function(e) {
    if (!canvas._puntos) return;
    var rect   = canvas.getBoundingClientRect();
    var mx     = e.clientX - rect.left;
    var puntos = canvas._puntos;
    var cercano = null, minDist = 15;
    puntos.forEach(function(p) {
        var d = Math.abs(p.x - mx);
        if (d < minDist) { minDist = d; cercano = p; }
    });
    if (cercano) {
        tooltip.innerHTML =
            '<b>' + cercano.label + '</b><br>' +
            '&#128101; Empleados: ' + cercano.empleados + '<br>' +
            '&#128998; Estr&#233;s: '    + cercano.estres     + '/10<br>' +
            '&#128309; Ansiedad: ' + cercano.desempenio + '/10<br>' +
            '&#128308; Bajas: '    + cercano.bajas;
        var tx = cercano.x + 8;
        if (tx + 130 > canvas.width) tx = cercano.x - 138;
        tooltip.style.left    = tx + 'px';
        tooltip.style.top     = '5px';
        tooltip.style.opacity = '1';
    } else {
        tooltip.style.opacity = '0';
    }
});

canvas.addEventListener('mouseleave', function() { tooltip.style.opacity = '0'; });
</script>

</body>
</html>
