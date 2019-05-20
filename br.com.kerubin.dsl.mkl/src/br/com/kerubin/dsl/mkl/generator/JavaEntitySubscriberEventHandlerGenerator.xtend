package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

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
		
		'''
		package «entity.package»;
		
		import java.util.Optional;
		
		import org.slf4j.Logger;
		import org.slf4j.LoggerFactory;
		import org.springframework.amqp.rabbit.annotation.RabbitListener;
		import org.springframework.beans.BeanUtils;
		import org.springframework.beans.factory.annotation.Autowired;
		«IF entity.hasSubscribeDeleted»
		import org.springframework.dao.DataIntegrityViolationException;
		«ENDIF»
		import org.springframework.stereotype.Service;
		
		«entity.getImportExternalEntityEvent»
		
		import br.com.kerubin.api.messaging.core.DomainEventEnvelope;
		
		@Service
		public class «entity.toSubscriberEventHandlerName» {
			
			private static final Logger log = LoggerFactory.getLogger(«entity.toSubscriberEventHandlerName».class);
			
			@Autowired
			private «entityDTOName»Repository «entityDTONameFirstLower»Repository;
			
			@Autowired
			private «entityDTOName»Service «entityDTONameFirstLower»Service;
			
			@RabbitListener(queues = "#{«entityDTONameFirstLower»Queue.name}")
			public void onReceiveEvent(DomainEventEnvelope<«entityDTOName»Event> envelope) {
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
				try {
					«entityDTONameFirstLower»Service.delete(«entityDTONameFirstLower»Event.getId());
				}
				catch(DataIntegrityViolationException e) {
					save«entityDTOName»(«entityDTONameFirstLower»Event, true);
				}
			}
			«ENDIF»
		
			private «entityDTOName»Entity build«entityDTOName»Entity(«entityDTOName»Event «entityDTONameFirstLower»Event) {
				«entityDTOName»Entity entity = new «entityDTOName»Entity();
				BeanUtils.copyProperties(«entityDTONameFirstLower»Event, entity);
				return entity;
			}
		
		}
		'''
	}
}