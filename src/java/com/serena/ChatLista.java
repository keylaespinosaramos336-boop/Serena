package com.serena;

public class ChatLista {
    
    private int idPsicologo; // 👈 NUEVO (IMPORTANTE)
    private String nombre;
    private String foto;
    private String ultimoMensaje;
    private int idChat;

    // 🔧 Constructor actualizado
    public ChatLista(int idPsicologo, String nombre, String foto, String ultimoMensaje, int idChat) {
        this.idPsicologo = idPsicologo;
        this.nombre = nombre;
        this.foto = foto;
        this.ultimoMensaje = ultimoMensaje;
        this.idChat = idChat;
    }

    // ✅ Getters
    public int getIdPsicologo() { return idPsicologo; }
    public String getNombre() { return nombre; }
    public String getFoto() { return foto; }
    public String getUltimoMensaje() { return ultimoMensaje; }
    public int getIdChat() { return idChat; }
}