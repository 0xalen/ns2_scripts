# ==================================================================== #
#	LICENCIA
#
#	Copyrigth (C) 2017 Franco Alejandro (0xalen)
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#	
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ==================================================================== #
#	DESCRIPCIÓN DEL PROGRAMA
#
#	Este programa es un modelo simple para una topología inalámbrica,
#	desarrollado en base a la documentación disponible en el manual (ver
#	isi.edu/nsnam/ns/doc/ns_doc.pdf).
#		
#	El script fue diseñado con el objetivo de explicar el funcionamiento
#	básico para topologías inalámbricas. En ámbito de producción podría
#	resultar más conveniente utilizar otras estructuras (e.g. al definir
#	el movimiento de los nodos).
# ==================================================================== # 

# ======================================================================
# Programa principal
# ======================================================================

# ----------------------------------------------------------------------
# Definir variables
# ----------------------------------------------------------------------
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             2                          ;# number of mobilenodes
set val(rp)             DSDV                       ;# routing protocol
set val(x)		300
set val(y)		300
#
set vel		50.0

# ----------------------------------------------------------------------
# Crear simulador y definir opciones básicas
# ----------------------------------------------------------------------

# Crear simulador
set ns_	[new Simulator]

# Crear archivo de traza
set tracefd     [open simple.tr w]
$ns_ trace-all $tracefd

# Crear archivo de traza de NAM
set ntf [open simple.nam w]
$ns_ namtrace-all-wireless $ntf $val(x) $val(y)

# Definir procedimiento de salida
proc finish {} {
    global ns_ tracefd ntf
    $ns_ flush-trace
    close $tracefd
    close $ntf
    exec nam simple.nam &
	exit 0    
}

# Definir topografia del objeto 
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Crear objeto God (General Operations Director)
create-god $val(nn)

# ----------------------------------------------------------------------
# Crear un número especifico de nodos moviles [val(nn)] y "enlazarlos" 
# al canal.
# A continuacion se crean dos nodos: node(0) y node(1)
# ----------------------------------------------------------------------
# Nuevo API para la configuracion de nodos: 
# 1. Crear canal (o multiples canales);
# 2. Especificar canal en node-config (en lugar de channelType);
# 3. Crear nodos para simulaciones.
#
# Crear canal #1
set chan_1_ [new $val(chan)]

# Configurar nodo inalámbrico
$ns_ node-config -adhocRouting $val(rp) \
		-llType $val(ll) \
		-macType $val(mac) \
		-ifqType $val(ifq) \
		-ifqLen $val(ifqlen) \
		-antType $val(ant) \
		-propType $val(prop) \
		-phyType $val(netif) \
		-topoInstance $topo \
		-agentTrace ON \
		-routerTrace ON \
		-macTrace ON \
		-movementTrace OFF \
		-channel $chan_1_ 
			

# NOTA: Para definir nodos en distintos canales, ver wireles-mitf.tcl			 
for {set i 0} {$i < $val(nn) } {incr i} {
	set node_($i) [$ns_ node]	
	$node_($i) random-motion 0 ;# Desactivar movimiento aleatorio
}

# ----------------------------------------------------------------------
# Definir coordenadas iniciales para los nodos moviles (x, y, z=0)
# ----------------------------------------------------------------------

$node_(0) set X_ 5.0
$node_(0) set Y_ 2.0
$node_(0) set Z_ 0.0

$node_(1) set X_ 50.0
$node_(1) set Y_ 50.0
$node_(1) set Z_ 0.0

# ----------------------------------------------------------------------
# Definir movimiento simple para los nodos
# ----------------------------------------------------------------------
# 
$ns_ at 1.0 "$node_(0) setdest 10.0 10.0 15.0"
$ns_ at 1.0 "$node_(1) setdest 290.0 290.0 15.0"
#
$ns_ at 10.0 "$node_(0) setdest 10.0 290.0 $vel"
$ns_ at 10.0 "$node_(1) setdest 290.0 10.0 $vel"

$ns_ at 20.0 "$node_(0) setdest 290.0 290.0 $vel"
$ns_ at 20.0 "$node_(1) setdest 10.0 10.0 $vel"

$ns_ at 30.0 "$node_(0) setdest 10.0 10.0 $vel"
$ns_ at 30.0 "$node_(1) setdest 290.0 290.0 $vel"

$ns_ at 40.0 "$node_(0) setdest 150.0 200.0 $vel"
$ns_ at 40.0 "$node_(1) setdest 100.0 150.0 $vel"

$ns_ at 50.0 "$node_(0) setdest 50.0 150.0 $vel"
$ns_ at 50.0 "$node_(1) setdest 250.0 150.0 $vel"

$ns_ at 60.0 "$node_(0) setdest 299.0 299.0 $vel"
$ns_ at 60.0 "$node_(1) setdest 1.0 1.0 $vel"
# Node_(1) comienza alejarse de node_(0)
$ns_ at 80.0 "$node_(1) setdest 190.0 180.0 15.0" 

# ----------------------------------------------------------------------
# Establecer el trafico entre nodos
# ----------------------------------------------------------------------

# Conexiones TCP entre node_(0) y node_(1)

set tcp [new Agent/TCP]
$tcp set class_ 2

set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp
$ns_ attach-agent $node_(1) $sink
$ns_ connect $tcp $sink

set ftp [new Application/FTP]
$ftp attach-agent $tcp

$ns_ at 5.0 "$ftp start" 

# ----------------------------------------------------------------------
# Terminar simulación
# ----------------------------------------------------------------------

for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at 100.0 "$node_($i) reset";
}
$ns_ at 100.0 "finish"
$ns_ at 100.01 "puts \"TERMINANDO SIMULACION...\" ; $ns_ halt"

puts "Comenzando simulacion..."
$ns_ run
