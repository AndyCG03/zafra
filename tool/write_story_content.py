"""Authoring helper: writes only the new narrative catalog."""
import json
from pathlib import Path

cards = []

def chapter(arc, number, era, character, title, text, left, right, delay=3, next_title=None, variants=()):
    cid = f'historia_{arc}_{number:02}'
    def option(data):
        label, effects, flag, favor = data
        result = dict(text=label, effects=effects, setFlags=[flag], favorsCharacter=favor)
        if number < 8:
            result['scheduleCards'] = [dict(cardId=f'historia_{arc}_{number+1:02}',
                afterTurns=delay, title=next_title)]
        return result
    c = dict(id=cid, era=era, character=character, storyArc=arc,
        chapter=f'{"EL AGUA" if arc == "agua" else "EL PUERTO"} · {number}/8 · {title}',
        drawFromDeck=False, weight=1, text=text, left=option(left), right=option(right),
        memoryVariants=[dict(requiresFlags=[flag], text=copy) for flag, copy in variants])
    cards.append(c)

chapter('agua',1,'fundacional','la_lider_vecinal','La primera promesa',
 'El ciclón dejó rota la acequia. Queda agua para los barrios o para el ingenio que paga la próxima cosecha. Todos esperan tu primera promesa.',
 ('Primero los barrios',{'pueblo':6,'economia':-4},'agua_barrios','la_lider_vecinal'),
 ('Primero la cosecha',{'pueblo':-4,'economia':6},'agua_ingenio','la_economista'),next_title='Agua: revisar la primera promesa',
 variants=())
for o in (cards[-1]['left'],cards[-1]['right']):
    o['scheduleCards'].append(dict(cardId='historia_puerto_01',afterTurns=1,title='Puerto: financiar la reconstrucción'))
chapter('agua',2,'fundacional','la_economista','La factura',
 'Las cisternas de emergencia cuestan más cada día. Podemos reparar la acequia ahora o comprar tiempo con otro reparto.',
 ('Reparar la acequia',{'economia':-5,'aparatoDelEstado':4},'agua_obra','la_economista'),
 ('Mantener las cisternas',{'pueblo':5,'economia':-3},'agua_cisternas','la_lider_vecinal'),next_title='Agua: inspeccionar las obras',
 variants=[('agua_barrios','Los barrios recibieron agua, pero el ingenio perdió producción. La Economista trae la factura: reparar la acequia o sostener las cisternas.'),
 ('agua_ingenio','La cosecha pagó las primeras cuentas. En los barrios siguen esperando tu turno de agua. La Economista pide decidir entre obras y cisternas.')])
chapter('agua',3,'fundacional','el_pescador','La fuga',
 'Un pescador encuentra una fuga junto a los depósitos. Los vecinos ofrecen repararla; el General quiere encargarla a su brigada y controlar el canal.',
 ('Una cuadrilla vecinal',{'pueblo':4,'aparatoDelEstado':-3},'agua_vecinos','la_lider_vecinal'),
 ('La brigada del Estado',{'aparatoDelEstado':5,'economia':-3},'agua_brigada','el_general'),delay=5,next_title='Agua: modernizar el ingenio',
 variants=[('agua_obra','La acequia que aprobaste ya funciona, pero una fuga sigue vaciando los depósitos. El pescador propone que los vecinos vigilen las reparaciones.'),
 ('agua_cisternas','Mientras pagas cisternas, una fuga desperdicia agua en los depósitos. El pescador pregunta por qué nadie repara lo que ya tenemos.')])
chapter('agua',4,'consolidacion','la_ingeniera','Cerrar el circuito',
 'La Ingeniera puede reutilizar el agua del ingenio. La obra cuesta reservas ahora; un parche más barato permitirá terminar esta cosecha.',
 ('Instalar recirculación',{'economia':-5,'pueblo':4},'agua_recirculada','la_ingeniera'),
 ('Reparar lo imprescindible',{'economia':4,'aparatoDelEstado':-2},'agua_parche','la_economista'),delay=4,next_title='Agua: repartir la cosecha',
 variants=[('agua_vecinos','La cuadrilla vecinal señala dónde se pierde más agua. La Ingeniera usa sus notas para proponer un circuito de reutilización.'),
 ('agua_brigada','La brigada custodia el canal, pero custodiar no crea agua. La Ingeniera propone reutilizarla dentro del ingenio.')])
chapter('agua',5,'consolidacion','el_sindicalista','El reparto',
 'La cosecha está lista. Exportar todo repondría reservas; reservar una parte para los barrios cumpliría la promesa de compartir la recuperación.',
 ('Reservar para la isla',{'pueblo':5,'economia':-3},'agua_reparto','el_sindicalista'),
 ('Exportar la cosecha',{'economia':5,'pueblo':-3},'agua_exportacion','la_economista'),delay=5,next_title='Agua: afrontar la sequía',
 variants=[('agua_recirculada','La recirculación ahorró agua y la cosecha salió adelante. El Sindicalista exige que ese esfuerzo también llene las despensas de la isla.'),
 ('agua_parche','El parche aguantó hasta la cosecha. El Sindicalista advierte que venderla toda dejará a los barrios pagando otra vez la recuperación.')])
chapter('agua',6,'crisis','la_campesina','La sequía',
 'Las lluvias no llegan. La Campesina propone pactar cuotas con cada comarca. El General ofrece asegurar los pozos y decidir el reparto desde palacio.',
 ('Pactar cuotas públicas',{'pueblo':4,'aparatoDelEstado':-3},'agua_pacto','la_lider_vecinal'),
 ('Custodiar los pozos',{'aparatoDelEstado':5,'pueblo':-3},'agua_control','el_general'),delay=4,next_title='Agua: decidir quién administra',
 variants=[('agua_reparto','Los barrios recuerdan que compartiste la cosecha y aceptan discutir cuotas para la sequía. La Campesina pide sentarlos a la misma mesa.'),
 ('agua_exportacion','Las reservas que dejó la exportación compran tiempo, pero los barrios desconfían del reparto. La Campesina pide cuotas que cualquiera pueda revisar.')])
chapter('agua',7,'apertura','la_jurista','La llave',
 'La emergencia termina. La Jurista pregunta quién conservará las llaves de los depósitos: consejos locales con cuentas públicas o una autoridad nacional.',
 ('Consejos con auditoría',{'pueblo':5,'aparatoDelEstado':-3},'agua_local','la_jurista'),
 ('Autoridad nacional',{'aparatoDelEstado':4,'economia':-2},'agua_central','el_general'),delay=4,next_title='Agua: convertir la promesa en legado',
 variants=[('agua_pacto','El pacto de cuotas evitó que las comarcas se enfrentaran. La Jurista propone convertir esa mesa provisional en consejos que rindan cuentas.'),
 ('agua_control','La vigilancia mantuvo abiertos los pozos. Ahora la Jurista pide una fecha de salida para los soldados y reglas permanentes para el reparto.')])
chapter('agua',8,'contemporanea','el_cientifico','Lo que queda',
 'Una empresa ofrece renovar los depósitos a cambio de cobrar por el suministro. El Científico propone financiar una red común con tarifas solidarias. Tu primera promesa llega a su última decisión.',
 ('Una red común',{'pueblo':6,'economia':-4},'agua_legado_comun','el_cientifico'),
 ('Concesión regulada',{'economia':6,'aparatoDelEstado':-3},'agua_legado_privado','la_economista'),
 variants=[('agua_local','Los consejos publican sus cuentas y piden renovar los depósitos sin perder su voz. El Científico ofrece una red común; una empresa propone una concesión regulada.'),
 ('agua_central','La autoridad nacional unificó el reparto. Sus depósitos envejecen: renovar con fondos comunes o ceder el suministro a una empresa regulada.')])

chapter('puerto',1,'fundacional','el_diplomatico','La oferta',
 'Sin el muelle, la cosecha no saldrá de la isla. Un socio extranjero adelanta dinero; los talleres locales pueden repararlo más despacio sin pedir garantías.',
 ('Aceptar el adelanto',{'economia':5,'relacionesExteriores':3,'aparatoDelEstado':-3},'puerto_credito','el_diplomatico'),
 ('Contratar talleres locales',{'economia':-4,'aparatoDelEstado':4},'puerto_local','la_economista'),next_title='Puerto: revisar las condiciones')
chapter('puerto',2,'fundacional','la_economista','La letra pequeña',
 'El acuerdo del muelle debe pasar por el consejo. Publicar las cuentas retrasará la obra; firmar hoy acelerará la reparación con menos control público.',
 ('Publicar las cuentas',{'pueblo':4,'economia':-3},'puerto_transparente','la_economista'),
 ('Firmar por urgencia',{'economia':4,'pueblo':-3},'puerto_opaco','el_diplomatico'),delay=4,next_title='Puerto: elegir al operador',
 variants=[('puerto_credito','El adelanto exige prioridad para los barcos del prestamista. El Diplomático dice que es habitual. La Economista pide publicar la garantía antes de firmar.'),
 ('puerto_local','Los talleres locales necesitan más tiempo y un nuevo presupuesto. La Economista pide publicar las cuentas antes de ampliar el contrato.')])
chapter('puerto',3,'consolidacion','el_sindicalista','El operador',
 'El muelle vuelve a recibir barcos. Una cooperativa de estibadores quiere administrarlo; el socio extranjero ofrece más tráfico si obtiene una licencia exclusiva.',
 ('Cooperativa del muelle',{'pueblo':5,'economia':-3},'puerto_cooperativa','el_sindicalista'),
 ('Licencia exclusiva',{'economia':5,'relacionesExteriores':3,'pueblo':-3},'puerto_exclusiva','el_diplomatico'),delay=4,next_title='Puerto: escuchar a los estibadores',
 variants=[('puerto_transparente','Las cuentas públicas permitieron comparar ofertas. Los estibadores presentan una cooperativa; el socio extranjero pide exclusividad a cambio de traer más barcos.'),
 ('puerto_opaco','La firma urgente dejó dudas en el muelle. Los estibadores piden participar en su gestión; el socio extranjero quiere convertir el acuerdo provisional en exclusividad.')])
chapter('puerto',4,'consolidacion','el_sindicalista','La huelga',
 'Los estibadores paran por turnos agotadores. Negociar cuesta días de carga; el General ofrece reabrir el muelle bajo custodia militar.',
 ('Pactar nuevos turnos',{'pueblo':5,'economia':-4},'puerto_acuerdo_laboral','el_sindicalista'),
 ('Custodia militar',{'aparatoDelEstado':5,'pueblo':-4},'puerto_militar','el_general'),delay=5,next_title='Puerto: repartir el coste de la crisis',
 variants=[('puerto_cooperativa','La cooperativa que autorizaste también discute sus propios turnos. Sus estibadores paran y exigen que la participación alcance las condiciones de trabajo.'),
 ('puerto_exclusiva','El operador exclusivo aumentó la carga sin ampliar descansos. Los estibadores paran. El General ofrece reabrir el muelle por la fuerza.')])
chapter('puerto',5,'crisis','la_periodista','El almacén vacío',
 'Una mala temporada deja el almacén vacío y vencen las obligaciones del puerto. Renegociar molestará a los socios; usar el fondo de pensiones aplazará la factura.',
 ('Renegociar a la vista de todos',{'relacionesExteriores':-4,'pueblo':4},'puerto_deuda_negociada','la_periodista'),
 ('Usar el fondo de pensiones',{'economia':5,'pueblo':-4},'puerto_pensiones','la_economista'),delay=4,next_title='Puerto: revisar el contrato',
 variants=[('puerto_acuerdo_laboral','El pacto mantuvo trabajando al muelle, pero la mala temporada vació el almacén. Los estibadores piden que sus pensiones no paguen las obligaciones del puerto.'),
 ('puerto_militar','La custodia abrió el muelle, pero no trajo compradores. La Periodista encuentra obligaciones vencidas y pregunta quién asumirá la factura.')])
chapter('puerto',6,'apertura','la_jurista','El voto',
 'La Jurista propone revisar el contrato del puerto en consulta pública. Un decreto daría una respuesta rápida, pero dejaría fuera a quienes viven del muelle.',
 ('Consulta con las cuentas abiertas',{'pueblo':5,'aparatoDelEstado':-3},'puerto_consulta','la_jurista'),
 ('Resolver por decreto',{'aparatoDelEstado':5,'pueblo':-3},'puerto_decreto','el_general'),delay=5,next_title='Puerto: decidir la próxima licencia',
 variants=[('puerto_deuda_negociada','La renegociación reveló cuánto cuesta el puerto. La Jurista quiere que la isla vote el siguiente contrato con esas cuentas sobre la mesa.'),
 ('puerto_pensiones','Los pensionistas reclaman lo que prestaron al puerto. La Jurista exige que cualquier nuevo contrato explique cómo devolverlo antes de votarlo.')])
chapter('puerto',7,'contemporanea','el_emprendedor','Treinta años',
 'Vence la licencia del muelle. Los emprendedores locales proponen acceso compartido; un consorcio ofrece una inversión mayor a cambio de treinta años de exclusividad.',
 ('Acceso compartido',{'pueblo':4,'economia':-3},'puerto_abierto','el_emprendedor'),
 ('Exclusividad con inversión',{'economia':6,'aparatoDelEstado':-4},'puerto_monopolio','la_economista'),delay=3,next_title='Puerto: quién guarda las claves',
 variants=[('puerto_consulta','La consulta pidió que varios operadores pudieran usar el muelle. Un consorcio ofrece más inversión si renuncias a ese mandato por treinta años.'),
 ('puerto_decreto','El decreto estabilizó el contrato, pero ahora debes renovarlo. Los emprendedores locales piden acceso; un consorcio compra treinta años de exclusividad.')])
chapter('puerto',8,'futurista','la_activista_digital','Las claves',
 'El puerto funciona con un sistema automático. El proveedor ofrece abaratarlo si conserva las claves y los datos. La Activista Digital pide una auditoría y control público.',
 ('Auditar y conservar las claves',{'economia':-4,'aparatoDelEstado':5},'puerto_legado_autonomo','la_activista_digital'),
 ('El proveedor lo administra',{'economia':6,'aparatoDelEstado':-4},'puerto_legado_dependiente','el_magnate_tech'),
 variants=[('puerto_abierto','El muelle compartido ya conecta a varios operadores. La Activista Digital advierte que un único proveedor puede cerrarlo con una contraseña.'),
 ('puerto_monopolio','El consorcio modernizó el muelle y controla sus accesos. La Activista Digital pregunta si la isla conservará al menos las claves del sistema.')])

cards.append(dict(id='seguridad_alerta',era='fundacional',character='el_guardaeaspalda',
    drawFromDeck=False,storyArc='seguridad',chapter='SEGURIDAD · Una última oportunidad',weight=1,
    text='Has debilitado tu protección dos veces. Hay un plan de atentado: si no cambias nada, quedan cuatro decisiones antes de que actúen. El Guardaespaldas pide presupuesto para renovar la escolta.',
    left=dict(text='Renovar la escolta',effects={'economia':-5,'aparatoDelEstado':3},restoresSecurity=True),
    right=dict(text='Asumir el riesgo',effects={'pueblo':3})))

if __name__ == '__main__':
    from write_campaign_content import write_content
    write_content()
