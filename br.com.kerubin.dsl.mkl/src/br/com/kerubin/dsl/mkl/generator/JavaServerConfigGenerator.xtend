package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServerConfigGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/ServerConfig.java'
		generateFile(fileName, generateServerConfig)
	}
	
	def CharSequence generateServerConfig() {
		val domaAndService = service.toServiceConstantsName
		
		'''
		package «service.servicePackage»;
		
		import java.util.UUID;
		// import org.modelmapper.ModelMapper;
		// import org.modelmapper.convention.MatchingStrategies;
		import org.springframework.amqp.core.MessagePostProcessor;
		import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
		import org.springframework.amqp.rabbit.connection.ConnectionFactory;
		import org.springframework.boot.autoconfigure.amqp.SimpleRabbitListenerContainerFactoryConfigurer;
		import org.springframework.context.annotation.Bean;
		import org.springframework.context.annotation.Configuration;
		import br.com.kerubin.api.messaging.core.DomainEvent;
		
		@Configuration
		public class ServerConfig {
			
			// TODO: remover esse cara
			/*@Bean
			public ModelMapper modelMapper() {
				ModelMapper modelMapper = new ModelMapper();
				modelMapper.getConfiguration().setMatchingStrategy(MatchingStrategies.STRICT);
				return modelMapper;
			}*/
			
			@Bean
			public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
					SimpleRabbitListenerContainerFactoryConfigurer configurer,
			        ConnectionFactory connectionFactory) {
				
			    SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
			    configurer.configure(factory, connectionFactory);
			    factory.setConsumerTagStrategy(queue -> {
			    	StringBuilder sb = new StringBuilder(DomainEvent.APPLICATION).append("_")
			    			.append(«domaAndService».DOMAIN)
			    			.append("_")
			    			.append(«domaAndService».SERVICE)
			    			.append("_")
			    			.append(UUID.randomUUID().toString())
			    			//.append(".to.")
			    			//.append(queue)
			    			;
			    	String tag = sb.toString();
			    	return tag;
			    });
			    
			    factory.setAfterReceivePostProcessors(afterReceivePostProcessors());
			    
			    return factory;
			}
			
			@Bean
			public MessagePostProcessor afterReceivePostProcessors() {
				return new MessageAfterReceivePostProcessors();
			}
		}
		'''
	}
	
}