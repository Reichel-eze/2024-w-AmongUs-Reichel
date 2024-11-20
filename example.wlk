class Jugador {
  const color
  const mochila = []              // una mochila que inicia vacía
  const tareasARealizar = []
  var property nivelDeSospecha = 40    // comienza en 40
  var puedeVotar = true
  var property estaVivo = true         // en un comienzo esta vivo

  //method nivelDeSospecha() = nivelDeSospechaBase

  method aumentarNivelDeSospechaEn(cantidad) {
    nivelDeSospecha += cantidad
  }

  method disminuirNivelDeSospechaEn(cantidad) {
    nivelDeSospecha -= cantidad
  }

  // 1)
  method esSospechoso() = nivelDeSospecha > 50

  // 2)
  method buscarUnItem(item) {
    mochila.add(item)
  }

  method tieneItem(item) {
    mochila.contains(item)
  }

  method usarItem(item) {
    mochila.remove(item)
  }

  method mochilaVacia() = mochila.isEmpty()

  method realizarTarea(){}        // metodo abstracto

  // 3) Saber si un jugador completó todas sus tareas. Los impostores siempre dicen que si
  method completoTodasSusTareas()      // metodo abstracto

  method impugnarVoto() {
    puedeVotar = false
  }

  // Cualquier jugador puede llamar a una reunión de emergencia

  method llamarAUnaReunionDeEmergencia() {
    nave.llamarAUnaReunionDeEmergencia()
  }

  method expulsar() {
    estaVivo = false
  }

}

class Tripulante inherits Jugador {
  var personalidad

  // 4) Pedirle a un jugador que realice cualquier tarea pendiente de entre las que puede realizar. 
  override method realizarTarea() {
    const tarea = self.tareaQuePuedeRealizar()
    self.tieneLosRequerimientosNecesariosPara(tarea)
    tarea.realizatePor(self)
    self.completarTarea(tarea)
  }

  // Busco alguna tarea que pueda realizar
  method tareaQuePuedeRealizar() = tareasARealizar.find({tarea => tarea.puedeRealizarla(self)})

  method tieneLosRequerimientosNecesariosPara(tarea){
    if(!tarea.puedeRealizarla(self))
      throw new DomainException(message = "El tripulante no cuenta con los requerimientos necesarios para realizar la tarea")
  }

  method completarTarea(tarea) {
    tareasARealizar.remove(tarea)   // 1ero saco la tarea de mis tareas pendientes ("voy vaciando mi lista de tareas pendientes")
    nave.seCompletoLaTarea()        // 2dos aviso a la nave que se completo la tarea  ("para que la nave se pregunte si se completaron todas las tareas")
    
  }

  override method completoTodasSusTareas() = tareasARealizar.isEmpty() // si la lista de tareas esta vacia significa que hizo todas sus tareas

  method voto() = personalidad.votoSegunPersonalidad()

}

class Impostor inherits Jugador {
  
  override method realizarTarea() {}           // no hace nada porque es impostor!!
  override method completoTodasSusTareas() = true   // "Los impostores siempre dicen que sí"

  method realizarSabotaje(sabotaje) {
    sabotaje.esRealizadoPor(self)
    self.aumentarNivelDeSospechaEn(5)
  }

  method voto() = nave.cualquierJugadorVivo()

}

// TAREAS

class Tarea {
  const itemsNecesarios = []

  method puedeRealizarla(tripulante) = itemsNecesarios.all({item => tripulante.tieneItem(item)})

  method realizatePor(tripulante) {
    self.usarItemsNecesarios(tripulante)
    self.consecuenciasDeRealizarla(tripulante)
  }

  method usarItemsNecesarios(tripulante) {
    itemsNecesarios.forEach({item => tripulante.usarItem(item)})
  }

  method consecuenciasDeRealizarla(tripulante) {}
}


object arreglarElTableroElectrico inherits Tarea (itemsNecesarios = ["llava inglesa"]) {
  
  //method puedeRealizarla(tripulante) = tripulante.tieneItem("llave inglesa")
  override method consecuenciasDeRealizarla(tripulante) { tripulante.aumentarNivelDeSospechaEn(10) }
}

object sacarLaBasura inherits Tarea (itemsNecesarios = ["escoba", "bolsa de consorcio"]) {

  //method puedeRealizarla(tripulante) = tripulante.tieneItem("escoba") and tripulante.tieneItem("bolsa de consorcio")
  override method consecuenciasDeRealizarla(tripulante) { tripulante.disminuirNivelDeSospechaEn(4) }
}

object ventilarLaNave inherits Tarea (itemsNecesarios = []) {

  //method puedeRealizarla(tripulante) = true   // no tiene requerimientos
  override method consecuenciasDeRealizarla(tripulante) { nave.aumentarNivelDeOxigenoEn(5) }
}


// LA NAVE

object nave {
  var nivelDeOxigeno = 200
  const jugadores = []
  //const impostores = []
  //const tripulantes = []
  

  method aumentarNivelDeOxigenoEn(cantidad) {
    nivelDeOxigeno += cantidad
  }

  method disminuirNivelDeOxigenoEn(cantidad) {
    nivelDeOxigeno -= cantidad
    self.validarVictoriaDeLosImpostores()
  }

  method validarVictoriaDeLosImpostores() {
    if(nivelDeOxigeno <= 0) 
      throw new DomainException(message = "Ganaron los impostores!!")
  }
 
  method seCompletoLaTarea() {
    if(self.seCompletaronTodasLasTareas())
      throw new DomainException(message = "Ganaron los tripulantes!!")
  }

  method seCompletaronTodasLasTareas() = jugadores.all({jugador => jugador.completoTodasSusTareas()})

  method alguienTieneItem(item) = jugadores.any({jugador => jugador.tieneItem(item)})

  method llamarAUnaReunionDeEmergencia() {
    const losVotos = self.votosDeJugadoresVivos()
    const elMasVotado = losVotos.max({alguien => losVotos.occurrencesOf(alguien)})  // 2dos) de toda la lista el que se tenga mas ocurrencias
    elMasVotado.expulsar()
  }

  method votosDeJugadoresVivos() = self.jugadoresVivos().map({jugador => jugador.voto()})  // 1ero) hago una lista de las votos de los jugadores vivos

  method cualquierJugadorVivo() = self.jugadoresVivos().anyOne()

  method jugadoresVivos() = jugadores.filter({jugador => jugador.estaVivo()})

  method alguienQueNoSeaSospechoso() = jugadores.filter({jugador => !jugador.esSospechoso()}).anyOne()

  method jugadorConMayorNivelDeSospecha() = jugadores.max({jugador => jugador.nivelDeSospecha()})

  method alguienQueTengaLaMochilaVacia() = jugadores.filter({jugador => jugador.mochilaVacia()}).anyOne()

}

// SABOTAJES

object reducirElOxigeno {
  method esRealizadoPor(impostor) {
    if(!nave.alguienTieneItem("tubo de oxigeno"))
      nave.disminuirNivelDeOxigenoEn(10)
  }
}

class ImpugnarAUnJugador {
  const jugadorImpugnado

  method esRealizadoPor(impostor) {
    jugadorImpugnado.impugnarVoto()
  }
}

// PERSONALIDAD

object troll {
  method votoSegunPersonalidad() = nave.alguienQueNoSeaSospechoso()
}

object detective {
  method votoSegunPersonalidad() = nave.jugadorConMayorNivelDeSospecha()
}

object materialista {
  method votoSegunPersonalidad() = nave.alguienQueTengaLaMochilaVacia()
}