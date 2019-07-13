package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule
import java.util.Set

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*

class JavaEntitySubscriberEventHandlerGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[hasSubscribeEntityEvents].forEach[generateEntityFile]
	}
	
	def generateEntityFile(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toSubscriberEventHandlerName + '.java'
		generateFile(fileName, entity.generateEntitySubscriberEventHandler)
	}
	
	def CharSequence generateEntitySubscriberEventHandler(Entity entity) {
		val entityDTOName = entity.toDtoName
		// val entityDTONameLower = entityDTOName.toLowerCase
		val entityDTONameFirstLower = entityDTOName.toFirstLower
		val ruleSubscribe = entity.getRuleSubscribe
		val imports = newLinkedHashSet
		var String ruleSubscribeCode = null;
		if (!ruleSubscribe.empty) {
			ruleSubscribeCode = ruleSubscribe.generateRuleSubscribe(imports)
		}
		
		'''
		package «entity.package»;
		
		import java.util.Optional;
		
		import org.slf4j.Logger;
		import org.slf4j.LoggerFactory;
		import org.springframework.amqp.AmqpRejectAndDontRequeueException;
		import org.springframework.amqp.rabbit.annotation.RabbitListener;
		import org.springframework.beans.factory.annotation.Autowired;
		«IF entity.hasSubscribeDeleted»
		import org.springframework.dao.DataIntegrityViolationException;
		«ENDIF»
		import org.springframework.stereotype.Service;
		«IF !imports.empty»
		«imports.join»
		«ENDIF»
		
		«entity.getImportExternalEntityEvent»
		
		import br.com.kerubin.api.messaging.core.DomainEventEnvelope;
		
		@Service
		public class «entity.toSubscriberEventHandlerName» {
			
			private static final Logger log = LoggerFactory.getLogger(«entity.toSubscriberEventHandlerName».class);
			
			@Autowired
			private «entityDTOName»Repository «entityDTONameFirstLower»Repository;
			
			@Autowired
			private «entityDTOName»Service «entityDTONameFirstLower»Service;
			
			@Autowired
			«entityDTOName»DTOConverter «entity.toDTOConverterVar»;
			
			@RabbitListener(queues = "#{«entityDTONameFirstLower»Queue.name}")
			public void onReceiveEvent(DomainEventEnvelope<«entityDTOName»Event> envelope) {
				// WARNING: all the code MUST be inside the try catch code. If an error occurs, must be throw AmqpRejectAndDontRequeueException.
				try {
					«IF ruleSubscribeCode !== null»
					«ruleSubscribeCode»
					«ENDIF»
					switch (envelope.getPrimitive()) {
					«IF entity.hasSubscribeCreated»
					case «entityDTOName»Event.«entity.toEntityEventConstantName('created')»:
					«ENDIF»
					«IF entity.hasSubscribeUpdated»
					case «entityDTOName»Event.«entity.toEntityEventConstantName('updated')»:
					«ENDIF»
					«IF entity.hasSubscribeCreated || entity.hasSubscribeUpdated»
					
						save«entityDTOName»(envelope.getPayload());
						break;
					«ENDIF»
					«IF entity.hasSubscribeDeleted»
					
					case «entityDTOName»Event.«entity.toEntityEventConstantName('deleted')»:
						delete«entityDTOName»(envelope.getPayload());
						break;
					«ENDIF»
					
					default:
						log.warn("Unexpected entity event: {} for: {}.", envelope.getPrimitive(), "«entity.externalEntityPakage + '.' + entity.toDtoName»");
						break;
					}
				} catch(Exception e) {
					log.error("Error receiven event with envelope: " + envelope, e);
					throw new AmqpRejectAndDontRequeueException(e);
				}
			}
			
			«IF entity.hasSubscribeDeleted»
			private void save«entityDTOName»(«entityDTOName»Event «entityDTONameFirstLower»Event) {
				save«entityDTOName»(«entityDTONameFirstLower»Event, false);
			}
			«ENDIF»
			
			private void save«entityDTOName»(«entityDTOName»Event «entityDTONameFirstLower»Event«IF entity.hasSubscribeDeleted», boolean isDeleted«ENDIF») {
				«entityDTOName»Entity entity = build«entityDTOName»Entity(«entityDTONameFirstLower»Event);
				Optional<«entityDTOName»Entity> optionalEntity = «entityDTONameFirstLower»Repository.findById(«entityDTONameFirstLower»Event.getId());
				if (optionalEntity.isPresent()) {
					«IF entity.hasSubscribeDeleted»
					if (isDeleted) {
						entity = optionalEntity.get();
						entity.setDeleted(true);
					}
					«ENDIF»
					«entityDTONameFirstLower»Service.update(entity.getId(), entity);
				}
				else {
					«entityDTONameFirstLower»Service.create(entity);
				}
			}
			
			«IF entity.hasSubscribeDeleted»
			private void delete«entityDTOName»(«entityDTOName»Event «entityDTONameFirstLower»Event) {
				Optional<«entityDTOName»Entity> optionalEntity = «entityDTONameFirstLower»Repository.findById(«entityDTONameFirstLower»Event.getId());
				if (optionalEntity.isPresent()) {
					try {
						«entityDTONameFirstLower»Service.delete(«entityDTONameFirstLower»Event.getId());
					} catch(DataIntegrityViolationException e) {
						log.warn("Record cannot be deleted, will be deactivated instead: " + «entityDTONameFirstLower»Event);
						try {
							save«entityDTOName»(«entityDTONameFirstLower»Event, true);
						} catch(Exception e2) {
							log.error("Record cannot be deactivated: " + «entityDTONameFirstLower»Event, e2);
						}
					}
				}
			}
			«ENDIF»
		
			private «entityDTOName»Entity build«entityDTOName»Entity(«entityDTOName»Event «entityDTONameFirstLower»Event) {
				«entityDTOName»Entity entity = «entity.toDTOConverterVar».convertDtoToEntity(«entityDTONameFirstLower»Event);
				return entity;
			}
		
		}
		'''
	}
	
	def String generateRuleSubscribe(Iterable<Rule> rules, Set<String> imports) {
		val rule = rules.head
		
		val whenExpression = rule.buildRuleWhenExpressionForJava(imports)
		'''
		// Begin code from Subscribe Rule
		boolean accepted = «whenExpression»;
		if (!accepted) {
			return; // Rejects this subscribe.
		}
		// End code from Subscribe Rule
		
		'''.toString
		
	}
	
}