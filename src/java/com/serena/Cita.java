package com.serena;

public class Cita {
    private int idCita;
    private String nombrePaciente;
    private String fecha;
    private String hora;
    private String modalidad;

    public Cita(int idCita, String nombrePaciente, String fecha, String hora, String modalidad) {
        this.idCita = idCita;
        this.nombrePaciente = nombrePaciente;
        this.fecha = fecha;
        this.hora = hora;
        this.modalidad = modalidad;
    }

    // Getters
    public int getIdCita() { return idCita; }
    public String getNombrePaciente() { return nombrePaciente; }
    public String getFecha() { return fecha; }
    public String getHora() { return hora; }
    public String getModalidad() { return modalidad; }
}