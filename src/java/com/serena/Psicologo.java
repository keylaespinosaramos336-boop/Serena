package com.serena;

public class Psicologo {
    private int id;
    private String nombre;
    private String especialidad;
    private String foto;
    private String experiencia;
    private String cedula;
    private String modalidad;

    // Constructor exacto para los 7 campos que extraes en el Servlet
    public Psicologo(int id, String nombre, String especialidad, String foto, String experiencia, String cedula, String modalidad) {
        this.id = id;
        this.nombre = nombre;
        this.especialidad = especialidad;
        this.foto = foto;
        this.experiencia = experiencia;
        this.cedula = cedula;
        this.modalidad = modalidad;
    }

    public int getId() { return id; }
    public String getNombre() { return nombre; }
    public String getEspecialidad() { return especialidad; }
    public String getFoto() { return foto; }
    public String getExperiencia() { return experiencia; }
    public String getCedula() { return cedula; }
    public String getModalidad() { return modalidad; }
}