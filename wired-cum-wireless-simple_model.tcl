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
#	Este programa es un modelo simple para una topología híbrica (cableada
#	e inalámbrica) desarrollado en base a la documentación disponible en
#	el manual (ver isi.edu/nsnam/ns/doc/ns_doc.pdf).
#		
#	El script fue diseñado con el objetivo de explicar el funcionamiento
#	básico para topologías wired-cum-wireless. En ámbito de producción podría
#	resultar más conveniente utilizar otras estructuras (e.g. al definir
#	los nodos, su movimiento, etc).
# ==================================================================== # 

# ======================================================================
# Programa principal
# ======================================================================

# ---------------------------------------------------------------------
# Definir opciones
# ---------------------------------------------------------------------
global val
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             1                          ;# number of mobilenodes
set val(rp)             DSDV                       ;# routing protocol
set val(x)		200
set val(y)		200
#
set wired_nodes      1
set bs_nodes         1
#
set vel		50.0

# ----------------------------------------------------------------------
# Inicializar variables globales y crear archivos de traza
# ----------------------------------------------------------------------

# Crear simulador
set ns_	[new Simulator]

# Configuracion de enrutamiento jerarquico
$ns_ node-config -addressType hierarchical
AddrParams set domain_num_ 2         	 ; # Numero de dominios
lappend cluster_num 1 2                 ; # Numero de clusters por dominio 2 1 1
AddrParams set cluster_num_ $cluster_num ; 
lappend eilastlevel 1 1 1              ; # Numero de nodos por cluster    1 1 4 1
AddrParams set nodes_num_ $eilastlevel   ; # de cada domino

# Crear archivo de traza
set tracefd     [open simple-wcw.tr w]
$ns_ use-newtrace
$ns_ trace-all $tracefd

# Crear archivo de traza de NAM
set ntf [open simple-wcw.nam w]
$ns_ use-newtrace
$ns_ namtrace-all-wireless $ntf $val(x) $val(y)

# Definir procedimiento de salida
proc finish {} {
    global ns_ tracefd ntf
    $ns_ flush-trace
    close $tracefd
    close $ntf
    exec nam simple-wcw.nam &
	exit 0    
}

# Definir topografia del objeto 
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Crear objeto God (General Operations Director) 
# En wired-cum-wireless, God necesita saber el num de las interfaces wireless
create-god [expr $val(nn) + $bs_nodes]

# ----------------------------------------------------------------------
# Crear nodos
# NOTA: Para la creacion de cada nodo hay que pasar la direccion jerarquica
# del mismo. Formato de direccion (dominio.cluster.nodo)
# ----------------------------------------------------------------------

# ---------------------------------------------------------------------
# Crear nodos cableados (DOMINIO 0)

set wnode0 [$ns_ node 0.0.0]

# ---------------------------------------------------------------------
# Crear nodos inalambricos y base stations

# Crear canal #1
set chan_1_ [new $val(chan)]

# Configuracion para bs
$ns_ node-config -adhocRouting $val(rp) \
		-llType $val(ll) \
		-macType $val(mac) \
		-ifqType $val(ifq) \
		-ifqLen $val(ifqlen) \
		-antType $val(ant) \
		-propInstance [new $val(prop)] \
		-propType $val(prop) \
		-phyType $val(netif) \
		-topoInstance $topo \
		-wiredRouting ON \
		-agentTrace ON \
		-routerTrace ON \
		-macTrace ON \
		-movementTrace OFF \
		-channel $chan_1_ 

# ---------------------------------------------------------------------
# Crear BS	 (DOMINIO 1)
set BS0 [$ns_ node 1.0.0]
$BS0 random-motion 0

# Definir coordenadas iniciales para el bs (x, y, z=0)

$BS0 set X_ 10.0
$BS0 set Y_ 10.0
$BS0 set Z_ 0.0

# Configuracion para nodos moviles
$ns_ node-config -wiredRouting OFF

# ---------------------------------------------------------------------
# Crear nodos inalambricos (DOMINIO 2)

set node_2 [ $ns_ node 1.1.0]
$node_2 base-station [AddrParams addr2id [$BS0 node-addr]] ; # asigna al node_2 la dir jerarquica de BS(0)

# Definir coordenadas iniciales para los nodos moviles (x, y, z=0)

$node_2 set X_ 190.0
$node_2 set Y_ 190.0
$node_2 set Z_ 0.0

# Crear enlaces entre nodos cableados y nodos BS

$ns_ duplex-link $wnode0 $BS0 5Mb 2ms DropTail

$ns_ duplex-link-op $wnode0 $BS0 orient right


# ----------------------------------------------------------------------
# Definir movimiento simple para los nodos
# ----------------------------------------------------------------------

# 
$ns_ at 0.1 "$node_2 setdest 190.0 190.0 15.0"

#
$ns_ at 10.0 "$node_2 setdest 10.0 50.0 $vel"
$ns_ at 20.0 "$node_2 setdest 70.0 50.0 $vel"
$ns_ at 30.0 "$node_2 setdest 70.0 75.0 $vel"
$ns_ at 40.0 "$node_2 setdest 10.0 150.0 $vel"
$ns_ at 50.0 "$node_2 setdest 120.0 75.0 $vel"
$ns_ at 60.0 "$node_2 setdest 125.0 120.0 $vel"
$ns_ at 80.0 "$node_2 setdest 190.0 180.0 15.0" 

# ----------------------------------------------------------------------
# Establecer el trafico entre nodos
# ----------------------------------------------------------------------

# Trafico entre nodo cableado y nodo inalambrico
# De 0 a 2
set tcp02 [new Agent/TCP]
	$tcp02 set class_ 2

set sink02 [new Agent/TCPSink]
	$ns_ attach-agent $wnode0 $tcp02
	$ns_ attach-agent $node_2 $sink02
	$ns_ connect $tcp02 $sink02

set ftp02 [new Application/FTP]
	$ftp02 attach-agent $tcp02
	$ns_ at 10.0 "$ftp02 start" 
	$ns_ at 70.0 "$ftp02 stop" 
# de 2 a 0
set tcp20 [new Agent/TCP]
	$tcp20 set class_ 2

set sink20 [new Agent/TCPSink]
	$ns_ attach-agent $node_2 $tcp20
	$ns_ attach-agent $wnode0 $sink20
	$ns_ connect $tcp20 $sink20

set ftp20 [new Application/FTP]
	$ftp20 attach-agent $tcp20
	$ns_ at 10.0 "$ftp20 start"
	$ns_ at 70.0 "$ftp20 stop"

# ----------------------------------------------------------------------
# Finalizar de la simulacion
# ----------------------------------------------------------------------

$ns_ at 100.0 "finish"
$ns_ at 100.01 "puts \"TERMINANDO SIMULACION...\" ; $ns_ halt"

puts "Comenzando simulacion..."
$ns_ run
