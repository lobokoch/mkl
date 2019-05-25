package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaMessagingAfterReceivePostProcessorsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toMessageAfterReceivePostProcessorsName  + '.java'
		generateFile(fileName, doGenerate)
	}
	
	def CharSequence doGenerate() {
		val domainAndService = service.toServiceConstantsName
		
		'''
		package «service.servicePackage»;
		
		import static br.com.kerubin.api.messaging.utils.Utils.isEmpty;
		
		import org.slf4j.Logger;
		import org.slf4j.LoggerFactory;
		import org.springframework.amqp.AmqpException;
		import org.springframework.amqp.core.Message;
		import org.springframework.amqp.core.MessagePostProcessor;
		
		import br.com.kerubin.api.database.core.ServiceContext;
		import br.com.kerubin.api.messaging.core.DomainEventPublisher;
		
		import static br.com.kerubin.api.messaging.constants.MessagingConstants.HEADER_TENANT;
		import static br.com.kerubin.api.messaging.constants.MessagingConstants.HEADER_USER;
		
		public class «service.toMessageAfterReceivePostProcessorsName» implements MessagePostProcessor {
			
			private static final Logger log = LoggerFactory.getLogger(DomainEventPublisher.class);
				
			@Override
			public Message postProcessMessage(Message message) throws AmqpException {
				
				Object tenant = message.getMessageProperties().getHeaders().get(HEADER_TENANT);
				Object user = message.getMessageProperties().getHeaders().get(HEADER_USER);
				
				if (isEmpty(tenant) || isEmpty(user)) {
					log.error("Empty or null tenant/user received from broker in message header tenant: {}, user: {}, message: ", tenant, user, message);
					
					throw new IllegalStateException("Empty or null tenant/user received from broker in message header tenant: " + tenant + ", user: " + user);
				}
				
				ServiceContext.setTenant(tenant.toString());
				ServiceContext.setUser(user.toString());
				
				ServiceContext.setDomain(«domainAndService».DOMAIN);
				ServiceContext.setService(«domainAndService».SERVICE);
				
				return message;
			}
		
		}

		'''
	}
	
}