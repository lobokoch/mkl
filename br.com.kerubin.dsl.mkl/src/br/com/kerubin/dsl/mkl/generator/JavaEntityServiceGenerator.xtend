package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.Slot
import java.util.Set

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*

class JavaEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[it |
			generateServiceInterface
			generateServiceInterfaceImpl
		]
	}
	
	def generateServiceInterface(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceName + '.java'
		generateFile(fileName, entity.generateEntityServiceInterface)
	}
	
	def generateServiceInterfaceImpl(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceImplName + '.java'
		generateFile(fileName, entity.generateEntityServiceInterfaceImpl)
	}
	
	def CharSequence generateEntityServiceInterface(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val ruleActions = entity.ruleActions
		
		'''
		package «entity.package»;
		
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		
		«IF entity.hasAutoComplete»
		import java.util.Collection;
		«ENDIF»
		
		public interface «entity.toServiceName» {
			
			public «entityName» create(«entityName» «entityVar»);
			
			public «entityName» read(«idType» «idVar»);
			
			public «entityName» update(«idType» «idVar», «entityName» «entityVar»);
			
			public void delete(«idType» «idVar»);
			
			public Page<«entityName»> list(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName», Pageable pageable);
			
			«IF entity.hasAutoComplete»
			public Collection<«entity.toAutoCompleteName»> autoComplete(String query);
			«ENDIF»
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
			«IF entity.hasSumFields»
			
			public «entity.toEntitySumFieldsName» get«entity.toEntitySumFieldsName»(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName»);
			«ENDIF»
			
			«ruleActions.map[generateRuleActionsInterfaceMethod].join»
		}
		'''
	}
	
	def CharSequence generateRuleActionsInterfaceMethod(Rule rule) {
		val actionName = rule.getRuleActionName
		val entity = (rule.owner as Entity)
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		'''
		public void «actionName»(«idType» «idVar»);
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		'''
		
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(String query);
		'''
	}
	
	def CharSequence generateEntityServiceInterfaceImpl(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val repositoryVar = entity.toRepositoryName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val getEntityMethod = 'get' + entityName
		val publishSlots = entity.getPublishSlots
		val entityEventName = entity.toEntityEventName
		val ruleActions = entity.ruleActions
		
		val imports = newLinkedHashSet
		
		val pakage = '''
		package «entity.package»;
		'''
		
		val preImports = ''' 
		
		import org.springframework.beans.BeanUtils;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		import org.springframework.stereotype.Service;
		import org.springframework.transaction.annotation.Transactional;
		
		import com.querydsl.core.types.Predicate;
		«IF entity.hasSumFields»
		import com.querydsl.core.types.Projections;
		import com.querydsl.jpa.impl.JPAQueryFactory;
		
		import javax.persistence.EntityManager;
		import javax.persistence.PersistenceContext;
		«ENDIF»
		
		import java.util.Optional;
		«IF entity.hasAutoComplete»
		import java.util.Collection;
		«ENDIF»
		«IF entity.hasPublishEntityEvents»
		import br.com.kerubin.api.messaging.core.DomainEntityEventsPublisher;
		import br.com.kerubin.api.messaging.core.DomainEvent;
		import br.com.kerubin.api.messaging.core.DomainEventEnvelope;
		import br.com.kerubin.api.messaging.core.DomainEventEnvelopeBuilder;
		«service.getImportServiceConstants»
		«ENDIF»
		'''
		
		val code = '''
		
		@Service
		public class «entity.toServiceImplName» implements «entity.toServiceName» {
			
			«IF entity.hasSumFields»
			@PersistenceContext
			private EntityManager em;
			
			«ENDIF»
			@Autowired
			private «entity.toRepositoryName» «repositoryVar»;
			
			@Autowired
			private «entity.toEntityListFilterPredicateName» «entity.toEntityListFilterPredicateName.toFirstLower»;
			
			«IF entity.hasPublishEntityEvents»
			@Autowired
			DomainEntityEventsPublisher publisher;
			«ENDIF»
			
			
			@Transactional
			public «entityName» create(«entityName» «entityVar») {
				«IF !entity.hasPublishCreated»
				return «repositoryVar».save(«entityVar»);
				«ELSE»
				«entityName» entity = «repositoryVar».save(«entityVar»);
				publishEvent(entity, «entityEventName».«entity.toEntityEventConstantName('created')»);
				return entity;
				«ENDIF»
			}
			
			@Transactional(readOnly = true)
			public «entityName» read(«idType» «idVar») {
				return «getEntityMethod»(«idVar»);
			}
			
			@Transactional
			public «entityName» update(«idType» «idVar», «entityName» «entityVar») {
				«entityName» entity = «getEntityMethod»(«idVar»);
				BeanUtils.copyProperties(«entityVar», entity, "«entity.id.name»");
				entity = «repositoryVar».save(entity);
				
				«IF entity.hasPublishUpdated»
				publishEvent(entity, «entityEventName».«entity.toEntityEventConstantName('updated')»);
				
				«ENDIF»
				return entity;
			}
			
			@Transactional
			public void delete(«idType» «idVar») {
				«repositoryVar».deleteById(«idVar»);
				
				«IF entity.hasPublishDeleted»
				«entityName» entity = new «entityName»();
				«entity.id.buildMethodSet('entity', idVar)»;
				publishEvent(entity, «entityEventName».«entity.toEntityEventConstantName('deleted')»);
				«ENDIF»
			}
			
			«IF entity.hasPublishEntityEvents»
			private void publishEvent(«entityName» entity, String eventName) {
				«entity.toEntityDomainEventTypeName» event = new «entityEventName»(«publishSlots.map[it.buildSlotGet].join(', ')»);
				DomainEventEnvelope<DomainEvent> envelope = DomainEventEnvelopeBuilder
						.getBuilder(eventName, event)
						.domain(«service.toServiceConstantsName».DOMAIN)
						.service(«service.toServiceConstantsName».SERVICE)
						.build();
				
				publisher.publish(envelope);
			}
			«ENDIF»
			
			@Transactional(readOnly = true)
			public Page<«entityName»> list(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName», Pageable pageable) {
				Predicate predicate = «entity.toEntityListFilterPredicateName.toFirstLower».mountAndGetPredicate(«entity.toEntityListFilterName»);
				
				Page<«entityName»> resultPage = «repositoryVar».findAll(predicate, pageable);
				return resultPage;
			}
			
			@Transactional(readOnly = true)
			private «entityName» «getEntityMethod»(«idType» «entity.id.name») {
				Optional<«entityName»> «entityVar» = «repositoryVar».findById(«idVar»);
				if (!«entityVar».isPresent()) {
					throw new IllegalArgumentException("«entityDTOName» not found:" + «idVar».toString());
				}
				return «entityVar».get();
			}
			
			«IF entity.hasAutoComplete»
			@Transactional(readOnly = true)
			public Collection<«entity.toAutoCompleteName»> autoComplete(String query) {
				Collection<«entity.toAutoCompleteName»> result = «repositoryVar».autoComplete(query);
				return result;
			}
			«ENDIF»
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoCompleteImpl].join»
			«ENDIF»
			
			«IF entity.hasSumFields»
			«entity.generateMethodGetContaPagarSumFields»
			«ENDIF»
			
			«ruleActions.map[generateRuleActionsImpl(imports)].join»
		}
		'''
		
		val result = pakage + preImports + imports.join + '\n' + code;
		
		result
	}
	
	def CharSequence generateRuleActionsImpl(Rule rule, Set<String> imports) {
		val actionName = rule.getRuleActionName
		val entity = (rule.owner as Entity)
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val entityName = entity.toEntityName
		val entityVar = entity.fieldName
		val getEntityMethod = 'get' + entityName
		val repositoryVar = entity.toRepositoryName.toFirstLower
		
		val whenExpression = rule.buildRuleWhenExpressionForJava(imports)
		var fieldValues = rule.apply.actionExpression.fieldValues
		val hasWhen = rule.hasWhen
		
		'''
		
		@Transactional
		@Override
		public void «actionName»(«idType» «idVar») {
			«entityName» «entityVar» = «getEntityMethod»(«idVar»);
			
			«IF hasWhen»if («whenExpression») {«ENDIF»
				«fieldValues.map[it.generateActionFieldAssign(entityVar, imports)].join»
				
				«entityVar» = «repositoryVar».save(«entityVar»);
			«IF hasWhen»}
			else {
				throw new IllegalStateException("Condição inválida para executar a ação: «actionName».");
			}
			«ENDIF»
			
		}
		'''
	}
	
	
	
	def CharSequence generateMethodGetContaPagarSumFields(Entity entity) {
		val entityName = entity.toEntityName
		val entityQueryDSLName = entity.toEntityQueryDSLName
		
		'''
		@Transactional(readOnly = true)
		public «entity.toEntitySumFieldsName» get«entity.toEntitySumFieldsName»(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName») {
			Predicate predicate = «entity.toEntityListFilterPredicateName.toFirstLower».mountAndGetPredicate(«entity.toEntityListFilterName»);
			
			«entityQueryDSLName» qEntity = «entityQueryDSLName».«entityName.toFirstLower»;
			JPAQueryFactory query = new JPAQueryFactory(em);
			«entity.toEntitySumFieldsName» result = query.select(
					Projections.bean(«entity.toEntitySumFieldsName».class, 
							«entity.sumFieldSlots.map[generateSumField].join(', \r')»
					))
			.from(qEntity)
			.where(predicate)
			.fetchOne();
			
			return result;
		}
		'''
	}
	
	def CharSequence generateSumField(Slot slot) {
		'''qEntity.«slot.fieldName».sum().as("«slot.sumFieldName»")'''
	}
	
	def CharSequence buildPublishEvent(Entity entity, String eventName) {
		val publishSlots = entity.getPublishSlots
		val entityEventName = entity.toEntityEventName
		'''
		«entity.toEntityDomainEventTypeName» event = new «entityEventName»(«publishSlots.map[it.buildSlotGet].join(', ')»);
		DomainEventEnvelope<DomainEvent> envelope = DomainEventEnvelopeBuilder
				.getBuilder(«entityEventName».«entity.toEntityEventConstantName('created')», event)
				.domain(«service.toServiceConstantsName».DOMAIN)
				.service(«service.toServiceConstantsName».SERVICE)
				.build();
		
		publisher.publish(envelope);
		'''
	}
	
	def CharSequence buildSlotGet(Slot slot) {
		var result = ''
		if (slot.isEntity)
			result = 'entity'.buildMethodGetEntityId(slot)
		else
			result = 'entity'.buildMethodGet(slot)
		result
	}
	
	def CharSequence generateListFilterAutoCompleteImpl(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val repositoryVar = slot.ownerEntity.toRepositoryName.toFirstLower
		
		'''
		
		@Transactional(readOnly = true)
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(String query) {
			Collection<«autoComplateName.toFirstUpper»> result = «repositoryVar».«autoComplateName»(query);
			return result;
		}
		'''
	}
	
}