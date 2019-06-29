package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntitySubscriberEventRabbitConfigGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
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
		val fileName = basePakage + entity.packagePath + '/' + entity.toSubscriberEventRabbitConfigName + '.java'
		generateFile(fileName, entity.generateEntitySubscriberEventRabbitConfig)
	}
	
	def CharSequence generateEntitySubscriberEventRabbitConfig(Entity entity) {
		val entiyNameFirstLower = entity.toDtoName.toFirstLower
		val externalEntityConstantsName = entity.toExternalServiceConstantsName
		
		'''
		package «entity.package»;
		
		import java.text.MessageFormat;
		
		import org.springframework.amqp.core.Binding;
		import org.springframework.amqp.core.BindingBuilder;
		import org.springframework.amqp.core.Queue;
		import org.springframework.amqp.core.TopicExchange;
		import org.springframework.beans.factory.annotation.Qualifier;
		import org.springframework.context.annotation.Bean;
		import org.springframework.context.annotation.ComponentScan;
		import org.springframework.context.annotation.Configuration;
		
		import br.com.kerubin.api.messaging.core.DomainEntityEventsPublisher;
		import br.com.kerubin.api.messaging.core.DomainEvent;
		
		«entity.getImportExternalServiceConstants»
		
		@ComponentScan({"br.com.kerubin.api.messaging.core"})
		@Configuration
		public class «entity.toDtoName»SubscriberEventRabbitConfig {
			
			private static final String ENTITY_NAME = "«entity.name»";
			private static final String ENTITY_KEY = "entity";
			
			@Bean
			public TopicExchange «entiyNameFirstLower»Topic() {
				String topicName = MessageFormat.format("{0}_{1}_{2}_{3}", 
					DomainEvent.APPLICATION, «externalEntityConstantsName».DOMAIN, 
					«externalEntityConstantsName».SERVICE, DomainEntityEventsPublisher.TOPIC_PREFFIX);
				
				return new TopicExchange(topicName);
			}
			
			@Bean
			public Queue «entiyNameFirstLower»Queue() {
				// This service queue name for subscribe to the entity owner exchange topic.
				String queueName = MessageFormat.format("{0}_{1}_{2}_{3}_{4}", 
					DomainEvent.APPLICATION, "«entity.service.domain»", "«entity.service.name»", ENTITY_KEY, ENTITY_NAME);
				
				return new Queue(queueName, true);
			}
			
			@Bean
			public Binding «entiyNameFirstLower»Binding(@Qualifier("«entiyNameFirstLower»Topic") TopicExchange topic, 
					@Qualifier("«entiyNameFirstLower»Queue") Queue queue) {
				
				String rountingKey = MessageFormat.format("{0}.{1}.{2}.{3}.{4}", 
						DomainEvent.APPLICATION, «externalEntityConstantsName».DOMAIN, 
						«externalEntityConstantsName».SERVICE, ENTITY_KEY, ENTITY_NAME);
				
				return BindingBuilder
						.bind(queue)
						.to(topic)
						.with(rountingKey);
			}
		
		}
		'''
	}
	
}