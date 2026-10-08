"""Author the campaign and shared consequences, including personal interludes."""
import json
from pathlib import Path
from write_story_content import cards as shared

new = []
def option(text, effects, flags=(), trust=None, **extra):
    return dict(text=text, effects=effects, setFlags=list(flags), trustChanges=trust or {}, **extra)
def gate(text, flags=(), min_trust=None, max_trust=None, excludes=()):
    return dict(text=text, requiresFlags=list(flags), excludesFlags=list(excludes),
                minTrust=min_trust or {}, maxTrust=max_trust or {})
def outcome(effects=None, flags=(), requires=(), feedback=None, minimum=None, maximum=None, excludes=()):
    return dict(effects=effects or {}, setFlags=list(flags), requiresFlags=list(requires),
                excludesFlags=list(excludes), feedback=feedback,
                minTrust=minimum or {}, maxTrust=maximum or {})
def schedule(target, title, delay=3):
    return dict(cardId=target,title=title,afterTurns=delay)
def scene(cid, era, character, chapter, text, left, right, variants=(), conditions=None, draw=False):
    c = dict(id=cid,era=era,character=character,storyArc='cosecha' if cid.startswith('cosecha_')
             else 'vida_cotidiana' if cid.startswith('humor_') else 'politica',
             chapter=chapter,text=text,left=left,right=right,memoryVariants=list(variants),
             drawFromDeck=draw,weight=2)
    if conditions: c['conditions']=conditions
    new.append(c)
    return c

# Existing decisions acquire rivals and consequences in the other storyline.
for c in shared:
    for side in ('left','right'):
        o=c[side]
        favored=o.get('favorsCharacter')
        if favored:
            o['trustChanges']={favored:1}
            if favored=='el_general': o['trustChanges']['la_lider_vecinal']=-1
            if favored=='la_lider_vecinal': o['trustChanges']['el_general']=-1
    if c['id']=='historia_agua_01':
        for o in (c['left'],c['right']):
            o['scheduleCards'].append(schedule('humor_radio','Cantina: la primera versión de tu promesa',2))
    if c['id']=='historia_puerto_03':
        for o in (c['left'],c['right']):
            o['scheduleCards'].append(schedule('cruce_contrato','Cosecha: cumplir lo prometido al puerto',2))
    if c['id']=='historia_agua_05':
        for o in (c['left'],c['right']):
            o['scheduleCards'].append(schedule('cosecha_01','Investigación: la cosecha desaparecida',3))
    if c['id']=='historia_agua_08':
        for o in (c['left'],c['right']): o['setFlags'].append('agua_resuelta')
    if c['id']=='historia_puerto_08':
        for o in (c['left'],c['right']):
            o['setFlags'].append('puerto_resuelto')
            o['scheduleCards']=[schedule('camp_transicion','Gobierno: decidir la sucesión',5)]
    if c['id']=='historia_puerto_04':
        c['left']['conditionalOutcomes']=[outcome({'pueblo':2},feedback='La Líder Vecinal respalda el acuerdo: los barrios se suman a la negociación.',minimum={'la_lider_vecinal':3})]
        c['right']['conditionalOutcomes']=[outcome({'aparatoDelEstado':-3},flags=['general_retiro_apoyo'],feedback='El General desconfía de ti y retira parte de la escolta del muelle.',maximum={'el_general':-3})]

scene('cruce_contrato','consolidacion','el_diplomatico','EL AGUA Y EL PUERTO · La misma factura',
 'El socio del puerto recuerda que sus barcos esperan una cosecha. Hay que cumplir el acuerdo o renegociarlo antes de que lleguen.',
 option('Compensar y cumplir',{'economia':-2,'relacionesExteriores':3},['contrato_pagado'],{'el_diplomatico':2,'la_economista':-1},
        conditionalOutcomes=[outcome({'economia':-2},requires=['agua_barrios'],feedback='Dar prioridad al agua de los barrios redujo la cosecha: la compensación cuesta más.')]),
 option('Renegociar la carga',{'relacionesExteriores':-3,'pueblo':2},['contrato_renegociado'],{'el_diplomatico':-2,'la_economista':1},
        conditionalOutcomes=[outcome({'economia':2},requires=['agua_ingenio'],feedback='El ingenio conservó producción; usas esa cosecha como garantía de la renegociación.')]),
 [gate('El agua que reservaste para los barrios redujo la cosecha. El socio del puerto exige la carga prometida o una compensación.', ['agua_barrios']),
  gate('El ingenio que priorizaste tiene carga, pero el socio exige la fecha pactada. Puedes cumplir o aprovechar la cosecha para renegociar.', ['agua_ingenio'])])

scene('cosecha_01','consolidacion','el_archivero','LA COSECHA DESAPARECIDA · 1/8 · Los sacos',
 'Faltan veinte sacos en el almacén, pero el libro registra una entrega completa. El Archivero pide conservar los documentos antes de que alguien los corrija.',
 option('Abrir una investigación',{'economia':-2,'aparatoDelEstado':2},['misterio_investiga'],{'la_periodista':1,'el_general':-1}),
 option('Negociar antes de acusar',{'relacionesExteriores':2,'pueblo':-2},['misterio_negocia'],{'el_diplomatico':1,'la_economista':1}),
 [gate('La cooperativa del puerto registra una entrega completa, pero faltan veinte sacos. Una orden de la escolta permitió sacar carga del almacén.', ['puerto_cooperativa']),
  gate('El operador exclusivo declara entregada la cosecha. Faltan veinte sacos y aparece una compensación en el contrato. El Archivero conserva dos versiones.', ['puerto_exclusiva'])])
scene('cosecha_02','crisis','el_archivero','LA COSECHA DESAPARECIDA · 2/8 · Dos libros',
 'El Archivero guarda el libro del almacén y el manifiesto del barco. Copiarlos preservará una pista; entregar los originales al operador facilitará un acuerdo privado.',
 option('Guardar copias públicas',{'aparatoDelEstado':-2,'pueblo':3},['archivo_copiado'],{'la_periodista':1},
        conditionalOutcomes=[outcome(flags=['pista_escolta'],requires=['puerto_cooperativa'],feedback='La copia conserva una autorización de la escolta.'),
            outcome(flags=['pista_contrato'],requires=['puerto_exclusiva'],feedback='La copia conserva una cláusula de compensación del operador.')]),
 option('Negociar con los originales',{'economia':3,'pueblo':-2},['archivo_privado'],{'el_diplomatico':2,'la_periodista':-2}),
 [gate('La orden que sacó carga de la cooperativa lleva un sello de la escolta. El Archivero ofrece copiarla antes de entregar el expediente.', ['puerto_cooperativa']),
  gate('La compensación del operador exclusivo figura en un manifiesto, pero no en el otro. El Archivero puede copiar ambos.', ['puerto_exclusiva'])])
scene('cosecha_03','crisis','la_periodista','LA COSECHA DESAPARECIDA · 3/8 · El testigo',
 'Un estibador vio un barco salir de noche. La Periodista quiere protegerlo fuera del puerto. El General pide llevarlo a un recinto militar.',
 option('Proteger su identidad',{'economia':-2,'pueblo':3},['testigo_protegido'],{'la_periodista':2,'el_general':-1}),
 option('Custodia del General',{'aparatoDelEstado':3,'pueblo':-2},['testigo_custodiado'],{'el_general':2,'la_periodista':-2},
        conditionalOutcomes=[outcome({'pueblo':-2},['testigo_silenciado'],feedback='El General, convertido en rival, impide que el testigo vuelva a hablar con la prensa.',maximum={'el_general':-3})]),
 [gate('El testigo solo acepta declarar porque confía en la Periodista, a quien has respaldado. Pide protección fuera del puerto.',min_trust={'la_periodista':3}),
  gate('La Periodista recuerda tus acuerdos a puerta cerrada. El testigo teme que sus palabras terminen en manos de quienes investiga.',max_trust={'la_periodista':-3})])
scene('cosecha_04','apertura','la_jurista','LA COSECHA DESAPARECIDA · 4/8 · Una puerta legal',
 'La Jurista puede pedir una orden para revisar los depósitos. El operador ofrece abrir sus libros si la inspección se mantiene privada.',
 option('Solicitar una orden judicial',{'aparatoDelEstado':-2,'pueblo':2},['sello_judicial'],{'la_jurista':2,'el_general':-1}),
 option('Revisar los libros en privado',{'relacionesExteriores':2,'pueblo':-2},['misterio_trato'],{'el_diplomatico':1,'la_jurista':-1},
        conditionalOutcomes=[outcome(flags=['pista_contrato'],requires=['puerto_exclusiva'],feedback='El operador entrega su copia del contrato como parte del trato.'),
            outcome(flags=['pista_escolta'],requires=['puerto_cooperativa'],feedback='Los libros privados conservan el sello de la escolta.')]))
scene('cosecha_05','apertura','la_cantinera','LA COSECHA DESAPARECIDA · 5/8 · Lo que se oye',
 'La Cantinera asegura que los sacos no desaparecieron: aprendieron a nadar. Bajo la broma hay un nombre de barco. Puedes escucharlo o cerrar el rumor.',
 option('Escuchar sin revelar la fuente',{'economia':-1,'pueblo':2},['pista_barco'],{'la_cantinera':2,'la_periodista':1}),
 option('Ordenar que cese el rumor',{'aparatoDelEstado':2,'pueblo':-2},['rumor_cerrado'],{'la_cantinera':-2,'el_general':1}),
 [gate('«La cooperativa puso los sacos; la escolta puso las ruedas», dice la Cantinera. Entre chistes ofrece un nombre de barco.', ['puerto_cooperativa']),
  gate('«El contrato incluía entrega a domicilio. Nadie dijo a qué domicilio», bromea la Cantinera. Tiene un nombre de barco.', ['puerto_exclusiva'])])
scene('cosecha_06','contemporanea','el_cientifico','LA COSECHA DESAPARECIDA · 6/8 · Seguir el rastro',
 'El Científico puede comparar el azúcar de un depósito con las muestras de la cosecha. Sin documentos y una ruta, la coincidencia no basta para acusar a nadie.',
 option('Cruzar muestras y documentos',{'economia':-3,'aparatoDelEstado':2},['muestras_comparadas'],{'el_cientifico':2},
        conditionalOutcomes=[outcome(flags=['prueba_desvio_escolta'],requires=['pista_escolta','pista_barco'],feedback='La muestra y la autorización vinculan los sacos con un depósito usado por la escolta.'),
            outcome(flags=['prueba_desvio_contrato'],requires=['pista_contrato','pista_barco'],feedback='La muestra y el contrato vinculan los sacos con la compensación del operador.')]),
 option('Publicar el informe provisional',{'pueblo':2,'relacionesExteriores':-2},['informe_provisional'],{'la_periodista':1,'el_cientifico':-1}),
 [gate('El nombre del barco permite localizar un depósito. El Científico puede contrastar sus sacos con los documentos que conservaste.', ['pista_barco']),
  gate('El testigo dejó de hablar bajo custodia. El Científico advierte que un parecido entre muestras no reemplaza la ruta que falta.', ['testigo_silenciado'])])
scene('cosecha_07','contemporanea','la_periodista','LA COSECHA DESAPARECIDA · 7/8 · Publicar o guardar',
 'La Periodista quiere publicar el expediente. Aún puedes hacerlo público o reservarlo para negociar una restitución sin señalar culpables.',
 option('Publicar el expediente',{'relacionesExteriores':-2,'pueblo':3},['revelacion_pedida'],{'la_periodista':2,'el_general':-1},
        conditionalOutcomes=[outcome(flags=['misterio_revelado'],requires=['prueba_desvio_escolta'],feedback='Se publica la cadena de pruebas del depósito de la escolta.'),
            outcome(flags=['misterio_revelado'],requires=['prueba_desvio_contrato'],feedback='Se publica la cadena de pruebas de la compensación del operador.'),
            outcome({'relacionesExteriores':-2},['misterio_incierto'],excludes=['prueba_desvio_escolta','prueba_desvio_contrato'],feedback='El expediente publicado contiene sospechas, pero no una cadena de pruebas completa.')]),
 option('Restituir en silencio',{'economia':3,'pueblo':-3},['misterio_encubierto'],{'la_economista':1,'la_periodista':-3}),
 [gate('Los documentos y las muestras sitúan la cosecha en un depósito usado por la escolta. La Periodista pide publicar la cadena completa.', ['prueba_desvio_escolta']),
  gate('El operador descontó sacos como compensación sin declararlo al almacén. La Periodista pide publicar el contrato y las muestras.', ['prueba_desvio_contrato'])])
scene('cosecha_08','futurista','la_cientifica','LA COSECHA DESAPARECIDA · 8/8 · El archivo que queda',
 'La digitalización recupera el expediente. La Científica pide distinguir lo probado de lo sospechado y compensar a quienes cargaron con las pérdidas.',
 option('Abrir el archivo y reparar',{'economia':-3,'pueblo':3},['misterio_cerrado','misterio_reparado'],{'la_cientifica':2,'la_periodista':1},clearFlags=['misterio_encubierto']),
 option('Sellar el expediente',{'aparatoDelEstado':3,'pueblo':-3},['misterio_cerrado','misterio_encubierto'],{'el_general':1,'la_periodista':-2}),
 [gate('La cadena publicada prueba el desvío por la escolta. La Científica propone conservarla, limitar esas autorizaciones y reparar las pérdidas.', ['prueba_desvio_escolta','misterio_revelado']),
  gate('La cadena publicada prueba la compensación oculta del operador. La Científica propone corregir el contrato y reparar las pérdidas.', ['prueba_desvio_contrato','misterio_revelado']),
  gate('El expediente que reservaste sigue en el archivo digital. Puedes reconocer lo que ocultaste y reparar, o cerrar también esta copia.', ['misterio_encubierto']),
  gate('No reuniste una cadena completa de pruebas. La Científica propone admitir los límites del expediente y reparar sin inventar un culpable.', ['misterio_incierto'])])

scene('general_disputa','crisis','el_general','ALIANZAS · El precio del respaldo',
 'El General ofrece sostener al gobierno durante las protestas si su brigada queda fuera de las auditorías. Puedes aceptar ese precio o exigir las mismas reglas para todos.',
 option('Una brigada sin excepciones',{'aparatoDelEstado':-3,'pueblo':3},['general_auditado'],{'el_general':-2,'la_jurista':2}),
 option('Conceder la excepción',{'aparatoDelEstado':3,'pueblo':-3},['general_privilegios'],{'el_general':2,'la_lider_vecinal':-2}),
 [gate('El General recuerda las propuestas que has respaldado. Ofrece sostener al gobierno, pero pide que su brigada quede fuera de las auditorías.',min_trust={'el_general':3}),
  gate('El General ya no confía en ti. Retira su apoyo público y condiciona cualquier regreso a una excepción para su brigada.',max_trust={'el_general':-3})],
 conditions={'minTrust':{'el_general':3}},draw=True)
scene('lider_pacto','apertura','la_lider_vecinal','ALIANZAS · Una mesa para todos',
 'La Líder Vecinal puede llevar a los barrios a una mesa de negociación. Quiere reuniones públicas y presupuesto para los acuerdos, no una foto de apoyo.',
 option('Mesa pública con presupuesto',{'economia':-3,'pueblo':3},['lider_pacto'],{'la_lider_vecinal':2,'el_general':-1},
        conditionalOutcomes=[outcome({'aparatoDelEstado':2},feedback='La confianza de la Líder Vecinal permite que los barrios acepten sentarse a negociar.',minimum={'la_lider_vecinal':3})]),
 option('Una reunión solo en palacio',{'aparatoDelEstado':2,'pueblo':-2},['lider_foto'],{'la_lider_vecinal':-2,'el_general':1}),
 [gate('La Líder Vecinal confía en ti y puede reunir a los barrios durante la protesta. Su apoyo exige presupuesto y cuentas públicas.',min_trust={'la_lider_vecinal':3}),
  gate('La Líder Vecinal recuerda tus promesas incumplidas. Solo participará en una mesa con acuerdos públicos que los barrios puedan vigilar.',max_trust={'la_lider_vecinal':-3})],
 conditions={'minTrust':{'la_lider_vecinal':3}},draw=True)
scene('audiencia_pueblo','contemporanea','la_lider_vecinal','ALIANZAS · La protesta vuelve',
 'Vuelven las protestas. Los barrios quieren saber quién decidió el último reparto. Puedes abrir una audiencia o limitar el acceso a palacio.',
 option('Responder en audiencia pública',{'economia':-2,'pueblo':3},['audiencia_abierta'],{'la_lider_vecinal':1},
        conditionalOutcomes=[outcome({'aparatoDelEstado':2},feedback='La Líder Vecinal te respalda y convence a los barrios de esperar la audiencia.',minimum={'la_lider_vecinal':3}),
            outcome({'pueblo':-2},feedback='La Líder Vecinal desconfía: los barrios exigen garantías antes de aceptar tu palabra.',maximum={'la_lider_vecinal':-3})]),
 option('Limitar el acceso a palacio',{'aparatoDelEstado':3,'pueblo':-3},['palacio_cerrado'],{'el_general':1,'la_lider_vecinal':-2},
        conditionalOutcomes=[outcome({'aparatoDelEstado':-3},['general_retiro_apoyo'],feedback='El General retira su respaldo: las órdenes de cerrar palacio llegan sin la escolta prometida.',maximum={'el_general':-3})]),
 [gate('Los barrios vuelven a protestar, pero la Líder Vecinal pone su nombre junto al tuyo: ofrece una audiencia y exige que respondas en público.',min_trust={'la_lider_vecinal':3}),
  gate('Los barrios vuelven a protestar. La Líder Vecinal, ahora rival, exige garantías y se niega a defender al gobierno sin ellas.',max_trust={'la_lider_vecinal':-3})],
 conditions={'requiresFlags':['agua_resuelta']},draw=True)

scene('humor_radio','fundacional','la_cantinera','VIDA DE LA ISLA · La radio de la cantina',
 'La Cantinera anuncia que el gobierno ha descubierto una fuente inagotable de agua: sus discursos. Propone emitir el próximo parte con preguntas del barrio.',
 option('Aceptar las preguntas',{'pueblo':2,'economia':-1},['radio_abierta'],{'la_cantinera':1}),
 option('Preparar un parte oficial',{'aparatoDelEstado':2,'pueblo':-2},['radio_oficial'],{'la_cantinera':-1}),
 [gate('«Primero los barrios», repite la Cantinera. Ya venden vasos con tu promesa impresa, aunque todavía están vacíos. Propone preguntas en la radio.', ['agua_barrios']),
  gate('La Cantinera dice que el ingenio tiene tanta prioridad que pronto podrá votar. Propone que los barrios pregunten por su turno de agua en la radio.', ['agua_ingenio'])])
scene('humor_sello','consolidacion','el_vagabundo','VIDA DE LA ISLA · Un sello para existir',
 'El Vagabundo necesita un domicilio para solicitar casa y una casa para registrar domicilio. Pide una ventanilla que acepte personas sin dirección, aunque no tengan sello.',
 option('Abrir una ventanilla sin domicilio',{'pueblo':3,'economia':-2},['ventanilla_abierta'],{'el_vagabundo':1,'la_lider_vecinal':1}),
 option('Crear un registro provisional',{'aparatoDelEstado':2,'economia':-1},['registro_provisional'],{'el_vagabundo':-1}))
scene('humor_colas','apertura','el_vagabundo','VIDA DE LA ISLA · La cola de la cola',
 'La nueva oficina tiene dos colas: una para recibir turno y otra para demostrar que se recibió. El Vagabundo dice que al menos ahora sabe dónde pasar la tarde.',
 option('Unificar trámites',{'pueblo':3,'aparatoDelEstado':-2},['tramites_unificados'],{'el_vagabundo':1}),
 option('Abrir un turno de tarde',{'economia':-2,'aparatoDelEstado':2},['turno_tarde'],{'el_vagabundo':1}),
 [gate('La ventanilla que abriste acepta gente sin domicilio. Ahora pide un papel para certificar que no pidió papeles. El Vagabundo trae ambos formularios.', ['ventanilla_abierta']),
  gate('El registro provisional tiene una cola definitiva. El Vagabundo pregunta si su nuevo domicilio puede ser la propia fila.', ['registro_provisional'])])
scene('humor_estatua','contemporanea','la_cantinera','VIDA DE LA ISLA · Tu mejor perfil',
 'Un comité propone una estatua tuya. La Cantinera celebra que, por fin, un gobernante podrá escuchar sin interrumpir. El mismo presupuesto alcanza para una biblioteca.',
 option('Construir la biblioteca',{'economia':-2,'pueblo':3},['biblioteca_publica'],{'la_cantinera':1,'la_bibliotecaria':1}),
 option('Una estatua hecha por artistas locales',{'economia':-2,'aparatoDelEstado':2},['estatua_local'],{'la_artista':1}))

scene('camp_reparaciones','futurista','la_jurista','EL ÚLTIMO ACTO · Las cuentas de la isla',
 'La Jurista reúne las cuentas del agua, del puerto y del almacén. Antes de discutir quién seguirá gobernando, pide decidir qué obligaciones dejarás resueltas.',
 option('Publicar obligaciones y reparar',{'economia':-3,'pueblo':3},['cuentas_publicas'],{'la_jurista':2}),
 option('Reservar fondos para palacio',{'economia':2,'pueblo':-2},['reserva_palacio'],{'el_general':1,'la_jurista':-2}),
 [gate('Tu promesa de agua terminó en una red común. La Jurista pide publicar cómo se sostendrá, junto con las obligaciones pendientes del puerto y del almacén.', ['agua_legado_comun']),
  gate('El proveedor conserva las claves del puerto. La Jurista pide publicar cuánto costará recuperar el control antes de discutir la sucesión.', ['puerto_legado_dependiente'])])
scene('camp_transicion','futurista','la_maestra','EL ÚLTIMO ACTO · Después de ti',
 'La Maestra pregunta qué ocurrirá cuando dejes palacio. Los consejos ofrecen asumir la transición. Puedes entregar el gobierno con sus cuentas o prolongar tu mandato.',
 option('Entregar el gobierno y las cuentas',{'aparatoDelEstado':-2,'pueblo':2},['sucesion_comunidad'],{'la_maestra':1},endsStory=True),
 option('Seguir gobernando',{'aparatoDelEstado':2,'pueblo':-2},['sucesion_perpetua'],{'el_general':1}),
 [gate('Los consejos administran el agua y comparten el puerto sin depender de un proveedor. La Maestra cree que la isla ya puede gobernarse sin ti.', ['agua_legado_comun','agua_local','puerto_abierto','puerto_legado_autonomo']),
  gate('La isla tiene nuevas obras, pero el proveedor conserva las claves del puerto y los acreedores reclaman su parte. La Maestra pide una sucesión con cuentas claras.', ['puerto_legado_dependiente']),
  gate('El expediente del almacén sigue sellado. La Maestra pregunta si tu sucesor heredará también los silencios del gobierno.', ['misterio_encubierto'])],
 conditions={'requiresFlags':['agua_resuelta','puerto_resuelto','misterio_cerrado']})

# Scheduled continuation for the endless mode. The campaign follows the order below.
for n in range(1,8):
    c=next(c for c in new if c['id']==f'cosecha_{n:02}')
    for side in ('left','right'):
        c[side]['scheduleCards']=[schedule(f'cosecha_{n+1:02}',f'Investigación: capítulo {n+1} de la cosecha',3)]
for a,b,title in [('humor_radio','humor_sello','Barrio: un sello para existir'),
                  ('humor_sello','humor_colas','Barrio: revisar los trámites'),
                  ('humor_colas','humor_estatua','Cantina: tu mejor perfil')]:
    c=next(c for c in new if c['id']==a)
    for side in ('left','right'): c[side]['scheduleCards']=[schedule(b,title,5)]
c=next(c for c in new if c['id']=='cosecha_08')
for side in ('left','right'): c[side]['scheduleCards']=[schedule('camp_reparaciones','Gobierno: publicar las obligaciones',3),schedule('camp_transicion','Gobierno: decidir la sucesión',5)]

scene('personal_lider_01','fundacional','la_lider_vecinal','VIDAS · La marca en la pared',
 'La Líder Vecinal te enseña una marca de agua en la escuela: hasta allí llegó la inundación en que perdió a su hermano. El General cerró entonces el puente para salvar los depósitos. Ella quiere refugios; él sigue llamándolo una decisión necesaria.',
 option('Abrir refugios con los barrios',{'economia':-2,'pueblo':2},['refugios_vecinales'],{'la_lider_vecinal':1}),
 option('Exigir un plan común de evacuación',{'aparatoDelEstado':2,'economia':-1},['evacuacion_coordinada'],{'el_general':1,'la_lider_vecinal':1}))
scene('personal_general_01','consolidacion','el_general','VIDAS · Una llave en el bolsillo',
 'El General lleva la llave de la casa de su madre, que el ciclón dejó vacía. Sus soldados reparan techos sin uniforme; teme que pedir ayuda parezca debilidad. Puedes pagar una brigada abierta a civiles o reconocer oficialmente a la que ya trabaja.',
 option('Una brigada civil y militar',{'economia':-2,'pueblo':2},['brigada_compartida'],{'el_general':1,'la_lider_vecinal':1}),
 option('Reconocer la brigada existente',{'aparatoDelEstado':2,'pueblo':-1},['brigada_reconocida'],{'el_general':2}))
scene('personal_cantinera_01','consolidacion','la_cantinera','VIDAS · El billete bajo la caja',
 'La hija de la Cantinera compró un pasaje de salida: aquí no encuentra trabajo. Su madre cuenta chistes sobre el puerto, pero guarda el billete bajo la caja. Pide aprendices en los talleres; la hija pide que nadie le retire el derecho a marcharse.',
 option('Financiar aprendices sin retenerla',{'economia':-2,'pueblo':2},['aprendices_puerto'],{'la_cantinera':1}),
 option('Acordar una beca fuera de la isla',{'economia':-1,'relacionesExteriores':2},['beca_hija'],{'la_cantinera':1,'el_diplomatico':1}))
scene('personal_lider_02','apertura','la_lider_vecinal','VIDAS · Sentarse en el mismo banco',
 'La Líder quiere escuchar al General sobre el puente cerrado. No te pide un culpable elegido de antemano: pide testimonios y reglas para que nadie vuelva a quedarse atrás. Puedes abrir una memoria pública o comenzar una mediación sin cámaras.',
 option('Testimonios y protocolo público',{'aparatoDelEstado':-2,'pueblo':2},['memoria_puente'],{'la_lider_vecinal':1,'el_general':-1}),
 option('Mediación con acta acordada',{'economia':-1,'aparatoDelEstado':2},['mediacion_puente'],{'la_lider_vecinal':1,'el_general':1}),
 [gate('Los refugios que abriste ya tienen llaves vecinales. La Líder propone que sus responsables escuchen al General sobre el puente, antes de escribir el siguiente protocolo.', ['refugios_vecinales']),
  gate('El plan común reunió por primera vez a vecinos y escoltas. La Líder quiere explicar qué ocurrió en el puente y discutir las reglas con el General.', ['evacuacion_coordinada'])])
scene('personal_general_02','contemporanea','el_general','VIDAS · Devolver la llave',
 'La casa de su madre vuelve a tener techo. El General pregunta qué hacer con la brigada de emergencia: devolver sus tareas a los vecinos o mantenerla como servicio mixto. Por primera vez te habla de retirarse él también, algún día.',
 option('Devolver herramientas a los vecinos',{'aparatoDelEstado':-2,'pueblo':2},['general_relevo_civil'],{'la_lider_vecinal':1}),
 option('Servicio mixto con cuentas públicas',{'economia':-1,'aparatoDelEstado':2},['general_servicio_mixto'],{'el_general':1}),
 [gate('Los civiles y soldados de la brigada compartida ya se conocen por sus nombres. El General quiere decidir qué servicio quedará cuando termine la emergencia.', ['brigada_compartida']),
  gate('La brigada que reconociste reparó la casa de su madre. El General propone dejar sus tareas por escrito para que el uniforme no sea la única garantía.', ['brigada_reconocida'])])
scene('personal_cantinera_02','futurista','la_cantinera','VIDAS · Una mesa reservada',
 'Llega una carta de la hija de la Cantinera. Le va bien, pero pregunta si podría abrir un taller al regresar. Su madre ya apartó una mesa, aunque asegura que es «para quien pague primero». Puedes ofrecer herramientas a los retornados o un intercambio sin exigir el regreso.',
 option('Talleres abiertos para volver',{'economia':-2,'pueblo':2},['taller_retorno'],{'la_cantinera':1}),
 option('Intercambio desde ambos puertos',{'economia':-1,'relacionesExteriores':2},['intercambio_hija'],{'la_cantinera':1,'el_diplomatico':1}),
 [gate('Los aprendices que financiaste sostienen el taller del muelle. La hija de la Cantinera pregunta por carta si puede volver y trabajar con ellos, sin desplazar a nadie.', ['aprendices_puerto']),
  gate('La beca permitió que su hija aprendiera a reparar motores. La Cantinera trae una carta: quiere compartir ese oficio con la isla, desde aquí o desde el otro puerto.', ['beca_hija'])])

# Personal decisions matter again during the main story, beyond their immediate cost.
next(c for c in new if c['id']=='audiencia_pueblo')['left']['conditionalOutcomes'].append(
    outcome({'aparatoDelEstado':1},requires=['mediacion_puente'],feedback='La mediación dejó un acta común: vecinos y escoltas acuerdan cómo proteger la audiencia.'))
next(c for c in new if c['id']=='cruce_contrato')['left']['conditionalOutcomes'].append(
    outcome({'economia':1},requires=['aprendices_puerto'],feedback='Los aprendices reparan parte de la carga y reducen la compensación.'))
for source,target,title in [('historia_agua_02','personal_lider_01','Barrio: la marca en la escuela'),
                          ('humor_sello','personal_general_01','General: una llave en el bolsillo'),
                          ('historia_puerto_03','personal_cantinera_01','Cantina: el billete de su hija'),
                          ('personal_lider_01','personal_lider_02','Barrio: la memoria del puente'),
                          ('personal_general_01','personal_general_02','General: devolver las herramientas'),
                          ('personal_cantinera_01','personal_cantinera_02','Cantina: una mesa reservada')]:
    c=next(c for c in shared+new if c['id']==source)
    for side in ('left','right'): c[side].setdefault('scheduleCards',[]).append(schedule(target,title,4))

acts = [
 ('La promesa y la marea',['historia_agua_01','historia_puerto_01','historia_agua_02','personal_lider_01','historia_puerto_02','historia_agua_03','humor_radio']),
 ('La cosecha que no llegó',['historia_agua_04','historia_puerto_03','personal_cantinera_01','cruce_contrato','cosecha_01','historia_puerto_04','humor_sello','personal_general_01']),
 ('El precio de la confianza',['historia_agua_05','cosecha_02','general_disputa','historia_puerto_05','historia_agua_06','cosecha_03']),
 ('Quién puede preguntar',['cosecha_04','historia_agua_07','historia_puerto_06','cosecha_05','lider_pacto','personal_lider_02','humor_colas']),
 ('Lo que puede probarse',['historia_puerto_07','historia_agua_08','cosecha_06','cosecha_07','personal_general_02','audiencia_pueblo','humor_estatua']),
 ('La isla después de ti',['historia_puerto_08','cosecha_08','personal_cantinera_02','camp_reparaciones','camp_transicion']),
]
endings = [
 ('ending_transicion_pactada','La transición pactada','Entregas el gobierno con sus cuentas y sus desacuerdos a la vista. La isla sigue teniendo problemas, pero ya no necesita que todas sus decisiones pasen por ti.'),
 ('ending_comunidad_autonoma','La isla sin su gobernante','Los consejos sostienen la red común y el puerto compartido conserva sus claves. Dejaste instituciones y conocimientos que funcionan sin esperar una orden de palacio.'),
 ('ending_isla_acreedores','La isla de los acreedores','Las obras siguen en pie, pero los contratos y las claves del puerto pertenecen a quienes las financiaron. El siguiente gobierno recibe una isla que trabaja para pagar sus condiciones.'),
 ('ending_cosecha_silencio','Los sacos bajo la alfombra','El gobierno cambia de manos con el expediente del almacén sellado. Se devolvieron algunas cuentas; la isla heredó también las preguntas que decidiste callar.'),
 ('ending_gobierno_perpetuo','Otro mandato, la misma silla','La campaña cierra con tu decisión de permanecer en palacio. Los acuerdos que construiste siguen dependiendo de ti, y la Maestra empieza a escribir el siguiente capítulo.'),
]

def write_content():
    def write(path,data): Path(path).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    write('assets/cards/arcos_narrativos.json',shared)
    write('assets/cards/campana.json',dict(title='La isla después de ti',acts=[dict(title=t,cards=cs) for t,cs in acts],cards=new))
    existing=json.loads(Path('assets/cards/endings.json').read_text(encoding='utf-8-sig'))
    illustration=next(e['imageAsset'] for e in existing if e.get('isSurvival'))
    write('assets/cards/finales_historia.json',[dict(id=i,title=t,description=d,imageAsset=illustration,
        causedBy='aparatoDelEstado',wasAtMin=False,era='historia',isStoryEnding=True) for i,t,d in endings])

if __name__=='__main__': write_content()
