package br.com.kerubin.dsl.mkl.generator.messaging

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.toConstantName
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class JavaServerMessagingGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	public static val MESSAGING = 'messaging'
	public static val EVENT_MESSAGE_NOT_HANDLED_EXCEPTION = 'EventMessageNotHandledException'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		if (service.hasMessagingEventHandler) {
			generateFiles
		}
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val baseFileName = basePakage + service.servicePackagePath + '/' + MESSAGING  + '/'
		
		generateFile(baseFileName + EVENT_MESSAGE_NOT_HANDLED_EXCEPTION + '.java', generateEventMessageNotHandledException)
		generateFile(baseFileName + service.domain.toCamelCase + service.name.toCamelCase + 'EventConfig' + '.java', generateServiceEventConfig)
		generateFile(baseFileName + service.domain.toCamelCase + service.name.toCamelCase + 'EventHandler' + '.java', generateServiceEventHandler)
		generateFile(baseFileName + service.domain.toCamelCase + service.name.toCamelCase + 'ListenerEventHandler' + '.java', generateServiceListenerEventHandler)
	}
	
	
	
	def CharSequence generateServiceListenerEventHandler() {
		val serviceAndDomain = service.domain.toCamelCase + service.name.toCamelCase
		
		'''
		package «service.servicePackage».«MESSAGING»;
		
		import java.text.MessageFormat;
		
		import javax.inject.Inject;
		
		import org.springframework.amqp.AmqpRejectAndDontRequeueException;
		import org.springframework.amqp.rabbit.annotation.RabbitListener;
		import org.springframework.stereotype.Service;
		
		import br.com.kerubin.api.messaging.core.DomainMessage;
		import lombok.extern.slf4j.Slf4j;
		
		/**
		 * Starts handling all received messages from RabbitMQ for the queue «serviceAndDomain.toFirstLower»Queue.
		 * WARNING: The «serviceAndDomain»EventHandler interface must be implemented by the implementation module.
		 * */
		@Slf4j
		@Service
		public class «serviceAndDomain»ListenerEventHandler {
			
			@Inject
			private «serviceAndDomain»EventHandler «serviceAndDomain.toFirstLower»EventHandler;
			
			@RabbitListener(queues = "#{«serviceAndDomain.toFirstLower»Queue.name}")
			public void onHandleEventListener(DomainMessage message) {
				log.info("Handling event listener received message from broker RabbitMQ: {}", message);
				try {
					«serviceAndDomain.toFirstLower»EventHandler.handleEvent(message);
				} catch(Exception e) {
					log.error(MessageFormat.format("Error: {0}, handling message: {1}", e.getMessage(), message), e);
					throw new AmqpRejectAndDontRequeueException(e);
				}
			}
			
		}
		
		'''
	}
	
	def CharSequence generateServiceEventHandler() {
		val domainAndService = service.domain.toCamelCase + service.name.toCamelCase
		
		'''
		package «service.servicePackage».«MESSAGING»;
		
		import br.com.kerubin.api.messaging.core.DomainMessage;
		
		public interface «domainAndService»EventHandler {
		
			void handleEvent(DomainMessage message);
		
		}
		
		'''
	}
	
	def CharSequence generateServiceEventConfig() {
		val serviceConstantsName = service.toServiceConstantsName
		val domainAndService = service.domain.toCamelCase + service.name.toCamelCase
		val serviceMainQueue = domainAndService.toFirstLower + 'Queue'
		val serviceMainQueueConstant = serviceMainQueue.toConstantName
		
		'''
		package «service.servicePackage».«MESSAGING»;
		
		import java.text.MessageFormat;
		
		import org.springframework.amqp.core.Queue;
		import org.springframework.context.annotation.Bean;
		import org.springframework.context.annotation.ComponentScan;
		import org.springframework.context.annotation.Configuration;
		
		«service.getImportServiceConstants»
		import br.com.kerubin.api.messaging.core.DomainEventConstants;
		
		@ComponentScan({"br.com.kerubin.api.messaging.core"})
		@Configuration
		public class «domainAndService»EventConfig {
			
			public static final String «serviceMainQueueConstant» = "«serviceMainQueue»";
			
			@Bean
			public Queue «serviceMainQueue»() {
				// Default queue for this service.
				String queueName = MessageFormat.format("{0}_{1}_{2}", //
					DomainEventConstants.APPLICATION, //
					«serviceConstantsName».DOMAIN, //
					«serviceConstantsName».SERVICE); //
				
				return new Queue(queueName, true);
			}
		
		}
		
		'''	
	}
	
	def CharSequence generateEventMessageNotHandledException() {
		'''
		package «service.servicePackage».«MESSAGING»;
		
		public class «EVENT_MESSAGE_NOT_HANDLED_EXCEPTION» extends RuntimeException {
		
			private static final long serialVersionUID = 1L;
			
			public EventMessageNotHandledException(String message) {
				super(message);
			}
		
		}
		
		'''
	}
	
}