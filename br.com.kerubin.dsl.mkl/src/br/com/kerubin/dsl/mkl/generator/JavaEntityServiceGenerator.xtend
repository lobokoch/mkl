package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.Slot
import java.util.Set

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import br.com.kerubin.dsl.mkl.model.RepositoryFindBy
import br.com.kerubin.dsl.mkl.model.RuleTargetField
import br.com.kerubin.dsl.mkl.model.ModifierFunctionName

class JavaEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		
		entities.filter[it.canGenerateServiceInterface].forEach[generateServiceInterface]
		entities.filter[it.canGenerateServiceImpl].forEach[generateServiceInterfaceImpl]
		
		/*entities.forEach[it |
			generateServiceInterface
			generateServiceInterfaceImpl
		]*/
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
		entity.imports.clear
		
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val ruleActions = entity.ruleActions
		val ruleMakeCopies = entity.ruleMakeCopies
		val fkSlots = entity.getEntitySlots
		
		val findBySlots = entity.slots.filter[it.hasRepositoryFindBy && it.repositoryFindBy.exists[!it.hasCustom]]
		val findBy = findBySlots.map['public ' + it.repositoryFindBy.map[generateRepositoryFindByMethod(false, false) + ';'].join('\r\n')].join('\r\n')
		
		if (entity.hasAutoComplete) {
			entity.addImport('import java.util.Collection;')
		}
		entity.addImport('import org.springframework.data.domain.Page;')
		entity.addImport('import org.springframework.data.domain.Pageable;')
		
		'''
		package «entity.package»;
		
		«entity.imports.join('\r\n')»
		
		«fkSlots.getDistinctSlotsByEntityName.map[it.resolveSlotAutocompleteImport].join('\r\n')»
		
		public interface «entity.toServiceName» {
			
			public «entityName» create(«entityName» «entityVar»);
			
			public «entityName» read(«idType» «idVar»);
			
			public «entityName» update(«idType» «idVar», «entityName» «entityVar»);
			
			public void delete(«idType» «idVar»);
			
			public «entity.buildEntityDeleteInBulkMethdName»;
			
			public Page<«entityName»> list(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName», Pageable pageable);
			
			«IF entity.hasAutoComplete»
			public Collection<«entity.toAutoCompleteName»> autoComplete(String query);
			«ENDIF»
			
			«IF !fkSlots.empty»
			// Begin relationships autoComplete 
			«fkSlots.map[it.generateSlotAutoCompleteInterfaceMethod].join»
			// End relationships autoComplete
			«ENDIF»
			 
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
			«IF entity.hasSumFields»
			
			public «entity.toEntitySumFieldsName» get«entity.toEntitySumFieldsName»(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName»);
			«ENDIF»
			«ruleActions.map[generateRuleActionsInterfaceMethod].join»
			«ruleMakeCopies.map[generateRuleMakeCopiesActionsInterfaceMethod].join»
			«IF !findBy.isEmpty»
			// findBy methods
			«findBy»
			«ENDIF»
		}
		'''
	}
	
	/*def CharSequence generateInterfaceFindByForEntity(Slot slot) {
		val findByList = slot.repositoryFindBy;
		'''
		// findBy for field «slot.fieldName»
		«findByList.map[it.generateSlotFindBy].join»
		'''
	}*/
	
	
	def Object generateSlotAutoCompleteInterfaceMethod(Slot slot) {
		val entity = slot.asEntity
		val ownerEntity = slot.ownerEntity
		val entityDTOName = ownerEntity.toEntityDTOName
		val entityDTOVar = ownerEntity.toEntityDTOName.toFirstLower
		val hasAutoCompleteWithOwnerParams = slot.isAutoCompleteWithOwnerParams
		
		'''
		public Collection<«entity.toAutoCompleteName»> «slot.toSlotAutoCompleteName»(String query«IF hasAutoCompleteWithOwnerParams», «entityDTOName» «entityDTOVar»«ENDIF»);
		'''
	}
	
	def Object generateSlotsAutoCompleteImports(Slot slot) {
		'''
		«slot.resolveSlotAutocompleteImport»
		'''
	}
	
	def CharSequence generateRuleMakeCopiesActionsInterfaceMethod(Rule rule) {
		val actionName = rule.getRuleActionMakeCopiesName
		val entity = (rule.owner as Entity)
		val makeCopiesClassName = entity.toEntityMakeCopiesName
		val makeCopiesNameVar = entity.toEntityMakeCopiesName.toFirstLower
		
		'''
		
		public void «actionName»(«makeCopiesClassName» «makeCopiesNameVar»);
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
		entity.imports.clear
		
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
		val ruleMakeCopies = entity.ruleMakeCopies
		
		val rulesFormOnCreate = entity.rulesFormOnCreate
		val rulesFormOnUpdate = entity.rulesFormOnUpdate
		val fkSlots = entity.getEntitySlots
		
		//val imports = newLinkedHashSet
		val imports = entity.imports
		val fkSlotsDistinct = fkSlots.getDistinctSlotsByEntityName
		
		val rulesFormWithDisableCUD = entity.getRulesFormWithDisableCUD
		val ruleFormWithDisableCUDMethodName = entity.toRuleFormWithDisableCUDMethodName
		val rulesWithSlotAppyModifierFunction = entity.getRulesWithSlotAppyModifierFunction
		
		val rulesFormBeforeSave = entity.getRulesFormBeforeSave
		
		val findBySlots = entity.slots.filter[it.hasRepositoryFindBy && it.repositoryFindBy.exists[!it.hasCustom]]
		
		if (entity.hasAutoComplete) {
			entity.addImport('import java.util.Collection;')
		}
		
		entity.addImport('import org.springframework.data.domain.Page;')
		entity.addImport('import org.springframework.data.domain.Pageable;')
		
		val pakage = '''
		package «entity.package»;
		'''
		
		val preImports = ''' 
		
		// import org.springframework.beans.BeanUtils;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.stereotype.Service;
		import org.springframework.transaction.annotation.Transactional;
		
		import com.querydsl.core.types.Predicate;
		«IF entity.hasSumFields»
		import com.querydsl.core.types.Projections;
		import com.querydsl.jpa.impl.JPAQueryFactory;
		
		import javax.persistence.EntityManager;
		import javax.persistence.PersistenceContext;
		«ENDIF»
		«IF !ruleMakeCopies.empty»
		import org.apache.commons.lang3.StringUtils;
		«ENDIF»
		
		«IF entity.hasPublishEntityEvents»
		import br.com.kerubin.api.messaging.core.DomainEntityEventsPublisher;
		import br.com.kerubin.api.messaging.core.DomainEvent;
		import br.com.kerubin.api.messaging.core.DomainEventEnvelope;
		import br.com.kerubin.api.messaging.core.DomainEventEnvelopeBuilder;
		import br.com.kerubin.api.database.core.ServiceContext;
		«service.getImportServiceConstants»
		«ENDIF»
		«IF !fkSlots.empty»
		
		«fkSlots.getDistinctSlotsByEntityName.map[it.resolveSlotAutocompleteImport].join('\r\n')»
		
		«fkSlots.getDistinctSlotsByEntityName.map[it.resolveSlotRepositoryImport].join('\r\n')»
		
		«ENDIF»		
		'''
		
		val code = '''
		 
		@Service
		public class «entity.toServiceImplName» implements «entity.toServiceName» {
			«IF entity.hasPublishEntityEvents»
			private static final String ENTITY_KEY = "entity.«entity.name»";
			«ENDIF»
			
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
			«IF !fkSlotsDistinct.empty»
			
			«fkSlotsDistinct.map[it.generateSlotRepositoryInjection].join»
			«ENDIF»
			
			@Transactional
			@Override
			public «entityName» create(«entityName» «entityVar») {
				«IF !rulesFormBeforeSave.empty»
				«DO_RULES_FORM_BEFORE_SAVE_METHOD»(«entityVar»);
				«ENDIF»
				«IF !rulesFormWithDisableCUD.empty»
				«ruleFormWithDisableCUDMethodName»(«entityVar»);
				
				«ENDIF»
				«IF !rulesFormOnCreate.empty»
				ruleOnCreate(«entityVar»);
				
				«ENDIF»
				«IF !rulesWithSlotAppyModifierFunction.empty»
				
				// Begin Rules AppyModifierFunction
				«rulesWithSlotAppyModifierFunction.map[it.applyRulesWithSlotAppyModifierFunction].join»
				// End Rules AppyModifierFunction
				
				«ENDIF»
				«IF !entity.hasPublishCreated»
				return «repositoryVar».save(«entityVar»);
				«ELSE»
				«entityName» entity = «repositoryVar».save(«entityVar»);
				publishEvent(entity, «entityEventName».«entity.toEntityEventConstantName('created')»);
				return entity;
				«ENDIF»
			}
			«IF !rulesFormOnCreate.empty»
			
			protected void ruleOnCreate(«entityName» «entityVar») {
				«rulesFormOnCreate.map[generateRuleFormOnCreate(imports)].join»
			}
			
			«ENDIF»
			
			@Transactional(readOnly = true)
			@Override
			public «entityName» read(«idType» «idVar») {
				return «getEntityMethod»(«idVar»);
			}
			
			@Transactional
			@Override
			public «entityName» update(«idType» «idVar», «entityName» «entityVar») {
				«IF !rulesFormBeforeSave.empty»
				«DO_RULES_FORM_BEFORE_SAVE_METHOD»(«entityVar»);
				«ENDIF»
				«IF !rulesFormWithDisableCUD.empty»
				«ruleFormWithDisableCUDMethodName»(«entityVar»);
				
				«ENDIF»
				«IF !rulesFormOnUpdate.empty»
				ruleOnUpdate(«entityVar»);
				
				«ENDIF»
				«IF !rulesWithSlotAppyModifierFunction.empty»
								
				// Begin Rules AppyModifierFunction
				«rulesWithSlotAppyModifierFunction.map[it.applyRulesWithSlotAppyModifierFunction].join»
				// End Rules AppyModifierFunction
				
				«ENDIF»
				// «entityName» entity = «getEntityMethod»(«idVar»);
				// BeanUtils.copyProperties(«entityVar», entity, "«entity.id.name»");
				// entity = «repositoryVar».save(entity);
				
				«entityName» entity = «repositoryVar».save(«entityVar»);
				
				«IF entity.hasPublishUpdated»
				publishEvent(entity, «entityEventName».«entity.toEntityEventConstantName('updated')»);
				
				«ENDIF»
				return entity;
			}
			«IF !rulesFormOnUpdate.empty»
						
			protected void ruleOnUpdate(«entityName» «entityVar») {
				«rulesFormOnUpdate.map[generateRuleFormOnUpdate(imports)].join»
			}
			
			«ENDIF»
			«IF !rulesFormBeforeSave.empty»
			«rulesFormBeforeSave.generateRulesFormBeforeSave(imports)»
			«ENDIF»
			
			@Transactional
			@Override
			public void delete(«idType» «idVar») {
				«IF !rulesFormWithDisableCUD.empty»
				«ruleFormWithDisableCUDMethodName»(«getEntityMethod»(«idVar»));
				
				«ENDIF»
				«IF entity.hasPublishDeleted»
				
				// First load the delete candidate entity.
				«entityName» entity = «getEntityMethod»(«idVar»);
				«ENDIF»
				
				// Delete it.
				«repositoryVar».deleteById(«idVar»);
				
				// Force flush to the database, for relationship validation and must throw exception because of this here.
				«repositoryVar».flush();
				
				«IF entity.hasPublishDeleted»
				// Replicate the delete event.
				publishEvent(entity, «entityEventName».«entity.toEntityEventConstantName('deleted')»);
				«ENDIF»
			}
			
			@Transactional
			@Override
			public «entity.buildEntityDeleteInBulkMethdName» {
				// Delete it.
				«repositoryVar».«buildEntityDeleteInBulkMethdNameCall»;
				
				// Force flush to the database, for relationship validation and must throw exception because of this here.
				«repositoryVar».flush();
			}
			
			«IF entity.hasPublishEntityEvents»
			protected void publishEvent(«entityName» entity, String eventName) {
				«entity.toEntityDomainEventTypeName» event = new «entityEventName»(«publishSlots.map[it.buildSlotGet].join(', \r\n\t')»);
				
				DomainEventEnvelope<DomainEvent> envelope = DomainEventEnvelopeBuilder
						.getBuilder(eventName, event)
						.domain(«service.toServiceConstantsName».DOMAIN)
						.service(«service.toServiceConstantsName».SERVICE)
						.key(ENTITY_KEY)
						.tenant(ServiceContext.getTenant())
						.user(ServiceContext.getUser())
						.build();
				
				publisher.publish(envelope);
			}
			«ENDIF»
			
			@Transactional(readOnly = true)
			@Override
			public Page<«entityName»> list(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName», Pageable pageable) {
				Predicate predicate = «entity.toEntityListFilterPredicateName.toFirstLower».mountAndGetPredicate(«entity.toEntityListFilterName»);
				
				Page<«entityName»> resultPage = «repositoryVar».findAll(predicate, pageable);
				return resultPage;
			}
			
			@Transactional(readOnly = true)
			protected «entityName» «getEntityMethod»(«idType» «entity.id.name») {
				«entity.addImport('import java.util.Optional;')»
				Optional<«entityName»> «entityVar» = «repositoryVar».findById(«idVar»);
				if (!«entityVar».isPresent()) {
					throw new IllegalArgumentException("«entityDTOName» not found:" + «idVar».toString());
				}
				return «entityVar».get();
			}
			
			«IF entity.hasAutoComplete»
			@Transactional(readOnly = true)
			@Override
			public Collection<«entity.toAutoCompleteName»> autoComplete(String query) {
				Collection<«entity.toAutoCompleteName»> result = «repositoryVar».autoComplete(query);
				return result;
			}
			«ENDIF»
			«IF !fkSlots.empty»
			
			// Begin relationships autoComplete 
			«fkSlots.map[it.generateSlotAutoCompleteImplMethod].join»
			// End relationships autoComplete
			
			«ENDIF»
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoCompleteImpl].join»
			«ENDIF»
			
			«IF entity.hasSumFields»
			«entity.generateMethodGetContaPagarSumFields(imports)»
			«ENDIF»
			
			«ruleActions.map[generateRuleActionsImpl(imports)].join»
			«ruleMakeCopies.map[generateRuleMakeCopiesActionsImpl(imports)].join»
			«IF !rulesFormWithDisableCUD.empty»
			«rulesFormWithDisableCUD.head.generateRuleFormWithDisableCUD(imports)»
			«ENDIF»
			«IF !findBySlots.isEmpty»
			
			// findBy methods
			«findBySlots.map[it.generateFindByImplementations].join»
			«ENDIF»
		}
		'''
		
		val result = pakage + preImports + imports.join('\n\r') + '\n\r' + code;
		
		result
	}
	
	def CharSequence generateRulesFormBeforeSave(Iterable<Rule> rules, Set<String> imports) {
		val entity = rules.get(0).ruleOwnerEntity
		
		val entityName = entity.toEntityName
		val entityVar = entity.fieldName
		
		'''
		
		private void «DO_RULES_FORM_BEFORE_SAVE_METHOD»(«entityName» «entityVar») {
			«rules.map[it.buildApplyRuleFormBeforeSave(imports)].join»
		}
		
		'''
		
	}
	
	def CharSequence buildApplyRuleFormBeforeSave(Rule rule, Set<String> imports) {
		val hasWhen = rule.hasWhen
		var String whenExpression = 'false'
		if (hasWhen) {
			whenExpression = rule.buildRuleWhenExpressionForJava(imports)
		}
		
		val errorMessage = rule?.apply?.ruleError.buildRuleErrorMessageForJava(imports)
		
		'''
		
		if («whenExpression») {
			throw new IllegalStateException(«errorMessage»);
		}
		
		'''
		
	}
	
	def CharSequence applyRulesWithSlotAppyModifierFunction(Rule rule) {
		val slot = (rule.target as RuleTargetField).target.field
		val entity = slot.ownerEntity
		val entityVar = entity.toEntityName.toFirstLower
		val modifierFunction = rule.apply.modifierFunction
		val funcNameEnum = modifierFunction.function
		val funcParams = modifierFunction.funcParams
		val hasParams = modifierFunction.hasParams
		
		var params = ''
		if (hasParams) {
			params = funcParams.map['"' + it.paramStr + '"'].join(', ')
		}
		
		val fileName = slot.fieldName.toFirstUpper
		
		val funcName = switch funcNameEnum {
			case ModifierFunctionName.TRIM_LEFT: {
				val result = 'stripStart'
				entity.addImport('''import static org.apache.commons.lang3.StringUtils.«result»;''')
				result
			}
			case ModifierFunctionName.TRIM_RIGTH: {
				val result = 'stripEnd'
				entity.addImport('''import static org.apache.commons.lang3.StringUtils.«result»;''')
				result
			}
			default: {
				val result = 'strip'
				entity.addImport('''import static org.apache.commons.lang3.StringUtils.«result»;''')
				result
			}
		}
		
		'''
		if («entityVar».get«fileName»() != null) {
			«entityVar».set«fileName»(«funcName»(«entityVar».get«fileName»()«IF hasParams», «params»«ENDIF»));
		}
		'''
	}
	
	
	
	def CharSequence generateFindByImplementations(Slot slot) {
		'''
		«slot.repositoryFindBy.map[it.generateFindByImplementation].join»
		'''
	}
	
	def CharSequence generateFindByImplementation(RepositoryFindBy findByObj) {
		
		val findByMethod = findByObj.generateRepositoryFindByMethod(false, false)
		val findByMethodCall = findByObj.generateRepositoryFindByMethod(true, true)
		
		val slot = findByObj.ownerSlot
		val ownerEntity = slot.ownerEntity
		val repositoryVar = ownerEntity.toRepositoryName.toFirstLower
		val isFindBy = findByObj.isFindBy
		
		'''
		
		@Transactional«IF isFindBy»(readOnly = true)«ENDIF»
		@Override
		public «findByMethod» {
			
			«IF isFindBy»return «ENDIF»«repositoryVar».«findByMethodCall»;
			
		}
		'''
	}
	
	def CharSequence generateRuleFormWithDisableCUD(Rule rule, Set<String> imports) {
		val entity = rule.ruleOwnerEntity
		
		val entityName = entity.toEntityName
		val entityVar = entity.fieldName
		
		val methodName = entity.toRuleFormWithDisableCUDMethodName
		
		val hasWhen = rule.hasWhen
		var String whenExpression = 'true'
		if (hasWhen) {
			whenExpression = rule.buildRuleWhenExpressionForJava(imports)
		}
		
		'''
		protected void «methodName»(«entityName» «entityVar») {
			boolean expression = «whenExpression»;
			if (expression) {
				throw new IllegalStateException("Opeção não permitida para este objeto.");
			}	
			
		}
		'''
	}
	
	def CharSequence generateSlotRepositoryInjection(Slot slot) {
		val entity = slot.asEntity
		val repositoryClass = entity.toRepositoryName
		val repositoryVar = repositoryClass.toFirstLower
		
		'''
		@Autowired
		private «repositoryClass» «repositoryVar»;
		
		'''
	}
	
	def CharSequence generateSlotAutoCompleteImplMethod(Slot slot) {
		val entity = slot.asEntity
		val ownerEntity = slot.ownerEntity
		val entityDTOName = ownerEntity.toEntityDTOName
		val entityDTOVar = ownerEntity.toEntityDTOName.toFirstLower
		val repositoryVar = entity.toRepositoryName.toFirstLower
		val hasAutoCompleteWithOwnerParams = slot.isAutoCompleteWithOwnerParams
		
		'''
		@Transactional(readOnly = true)
		@Override
		public Collection<«entity.toAutoCompleteName»> «slot.toSlotAutoCompleteName»(String query«IF hasAutoCompleteWithOwnerParams», «entityDTOName» «entityDTOVar»«ENDIF») {
			Collection<«entity.toAutoCompleteName»> result = «repositoryVar».autoComplete(query);
			return result;
		}
		
		'''
	}
	
	def CharSequence generateRuleMakeCopiesActionsImpl(Rule rule, Set<String> imports) {
		val actionName = rule.getRuleActionMakeCopiesName
		val entity = (rule.owner as Entity)
		val entityName = entity.toEntityName
		val entityVar = entity.fieldName
		val getEntityMethod = 'get' + entityName
		
		val repositoryVar = entity.toRepositoryName.toFirstLower
		
		val makeCopiesClassName = entity.toEntityMakeCopiesName
		val makeCopiesNameVar = entity.toEntityMakeCopiesName.toFirstLower
		
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		val referenceField = rule.getRuleMakeCopiesReferenceField
		val getGrouperMethod =  makeCopiesNameVar + '.' + grouperField.buildMethodGet
		
		imports.add('import java.time.LocalDate;')
		imports.add('import java.util.List;')
		imports.add('import java.util.ArrayList;')
		imports.add('import java.time.temporal.ChronoUnit;')
		
		'''
		
		@Transactional
		@Override
		public void «actionName»(«makeCopiesClassName» «makeCopiesNameVar») {
			if (StringUtils.isBlank(«getGrouperMethod»)) {
				throw new IllegalArgumentException("O campo 'Agrupador' deve ser informado.");
			}
			
			«entityName» «entityVar» = «getEntityMethod»(«makeCopiesNameVar».«entity.id.buildMethodGet»);
			«grouperField.buildMethodSet(entityVar, getGrouperMethod)»;
			
			LocalDate lastDate = «entityVar».«referenceField.buildMethodGet»;
			List<«entityName»> copies = new ArrayList<>();
			long interval = «makeCopiesNameVar».getReferenceFieldInterval();
			int fixedDay = lastDate.getDayOfMonth();
			int fixedDayCopy = fixedDay;
			for (int i = 0; i < «makeCopiesNameVar».getNumberOfCopies(); i++) {
				«entityName» copiedEntity = «entityVar».clone();
				copies.add(copiedEntity);
				copiedEntity.«entity.id.buildMethodSet('null')»;
				lastDate = lastDate.plus(interval, ChronoUnit.DAYS);
				if (interval == 30) {
					int length = lastDate.lengthOfMonth();
					while (fixedDay > length) {
					    fixedDay--;
					}
					lastDate = lastDate.withDayOfMonth(fixedDay);
					fixedDay = fixedDayCopy;
				}
				copiedEntity.«referenceField.buildMethodSet('lastDate')»;
			}
			
			copies.add(«entityVar»);
			«repositoryVar».saveAll(copies);
		}
		'''
	}
	
	def static CharSequence generateRuleFormOnCreate(Rule rule, Set<String> imports) {
		val entity = (rule.owner as Entity)
		val entityVar = entity.toEntityName.toFirstLower
		
		rule.generateRuleFormOnCreate(imports, entityVar)
	}
	
	def static CharSequence generateRuleFormOnCreate(Rule rule, Set<String> imports, String entityVar) {
		var fieldValues = rule.apply.actionExpression.fieldValues
		
		'''
		«fieldValues.map[it.generateActionFieldAssign(entityVar, imports)].join»
		'''
	}
	
	def CharSequence generateRuleFormOnUpdate(Rule rule, Set<String> imports) {
		val entity = (rule.owner as Entity)
		val entityVar = entity.toEntityName.toFirstLower
		
		var fieldValues = rule.apply.actionExpression.fieldValues
		
		'''
		«fieldValues.map[it.generateActionFieldAssign(entityVar, imports)].join»
		'''
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
	
	
	
	def CharSequence generateMethodGetContaPagarSumFields(Entity entity, Set<String> imports) {
		imports.add('import java.math.BigDecimal;');
		
		val entityName = entity.toEntityName
		val entityQueryDSLName = entity.toEntityQueryDSLName
		
		'''
		@Transactional(readOnly = true)
		@Override
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
		'''qEntity.«slot.fieldName».sum().coalesce(BigDecimal.ZERO).as("«slot.sumFieldName»")'''
	}
	
	/*def CharSequence generateSumField(Slot slot) {
		'''qEntity.«slot.fieldName».sum().as("«slot.sumFieldName»")'''
	}*/
	
	def CharSequence buildPublishEvent(Entity entity, String eventName) {
		val publishSlots = entity.getPublishSlots
		val entityEventName = entity.toEntityEventName
		'''
		«entity.toEntityDomainEventTypeName» event = new «entityEventName»(«publishSlots.map[it.buildSlotGet].join(', \r\n\t')»);
		
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
		
		if (slot.name != '')
			
		result
	}
	
	def CharSequence generateListFilterAutoCompleteImpl(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val repositoryVar = slot.ownerEntity.toRepositoryName.toFirstLower
		
		'''
		
		@Transactional(readOnly = true)
		@Override
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(String query) {
			Collection<«autoComplateName.toFirstUpper»> result = «repositoryVar».«autoComplateName»(query);
			return result;
		}
		'''
	}
	
}