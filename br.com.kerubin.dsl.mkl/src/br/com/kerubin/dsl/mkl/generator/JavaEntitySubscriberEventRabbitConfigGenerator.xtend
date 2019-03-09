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
			
			@Bean
			public TopicExchange «entiyNameFirstLower»Topic() {
				return new TopicExchange(DomainEntityEventsPublisher.ENTITY_EVENTS_TOPIC_NAME);
			}
			
			@Bean
			public Queue «entiyNameFirstLower»Queue() {
				String queueName = MessageFormat.format("{0}_{1}_{2}_{3}", 
						DomainEvent.APPLICATION, «externalEntityConstantsName».DOMAIN, 
						«externalEntityConstantsName».SERVICE, DomainEntityEventsPublisher.ENTITY_EVENTS);
				
				return new Queue(queueName, true);
			}
			
			@Bean
			public Binding «entiyNameFirstLower»Binding(@Qualifier("«entiyNameFirstLower»Topic") TopicExchange topic, 
					@Qualifier("«entiyNameFirstLower»Queue") Queue queue) {
				
				String rountingKey = MessageFormat.format("{0}.{1}.{2}.{3}", 
						DomainEvent.APPLICATION, «externalEntityConstantsName».DOMAIN, 
						«externalEntityConstantsName».SERVICE, DomainEntityEventsPublisher.ENTITY_EVENTS);
				
				return BindingBuilder
						.bind(queue)
						.to(topic)
						.with(rountingKey);
			}
		
		}
		'''
	}
	
}