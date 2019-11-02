package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import br.com.kerubin.dsl.mkl.model.RepositoryFindBy

class JavaEntityControllerGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.canGenerateController].forEach[generateController]
	}
	
	def generateController(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toControllerName + '.java'
		generateFile(fileName, entity.generateEntityController)
	}
	
	def CharSequence generateEntityController(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val entityServiceVar = entity.toServiceName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val toDTO = 'convertEntityToDto'
		val toEntity = 'convertDtoToEntity'
		
		val ruleActions = entity.ruleActions
		val ruleMakeCopies = entity.ruleMakeCopies
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		
		val fkSlots = entity.getEntitySlots
		val fkSlotsDistinct = fkSlots.getDistinctSlotsByEntityName
		
		val isEnableDoc = entity.service.isEnableDoc
		val title = entity.title
		
		
		if (entity.hasAutoComplete) {
			entity.addImport('import java.util.Collection;')
		}
		
		entity.addImport('import org.springframework.data.domain.Page;')
		entity.addImport('import org.springframework.data.domain.Pageable;')
		
		val findBySlots = entity.slots.filter[it.hasRepositoryFindBy]
		val findBySlotsContent = findBySlots.map[it.generateFindByImplementations].join
		
		
		'''
		package «entity.package»;
		
		«IF entity.hasAutoComplete»
		import org.springframework.web.bind.annotation.RequestParam;
		«ENDIF»
		«IF !ruleActions.empty || !ruleMakeCopies.isEmpty»
		import org.springframework.web.server.ResponseStatusException;
		«ENDIF»
		import java.util.List;
		import java.util.stream.Collectors;
		
		import javax.validation.Valid;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.web.bind.annotation.RestController;
		import org.springframework.web.bind.annotation.RequestMapping;
		import org.springframework.web.bind.annotation.ResponseStatus;
		import org.springframework.transaction.annotation.Transactional;
		import org.springframework.http.ResponseEntity;
		import org.springframework.http.HttpStatus;
		
		import org.springframework.web.bind.annotation.PathVariable;
		import org.springframework.web.bind.annotation.RequestBody;
		import org.springframework.web.bind.annotation.PostMapping;
		import org.springframework.web.bind.annotation.GetMapping;
		import org.springframework.web.bind.annotation.PutMapping;
		import org.springframework.web.bind.annotation.DeleteMapping;
		
		«service.importPageResult»
		
		«IF !fkSlotsDistinct.empty»
				
		«fkSlotsDistinct.map[it.resolveSlotAutocompleteImport].join('\r\n')»
		
		«ENDIF»
		«IF isEnableDoc»
		import io.swagger.annotations.Api;
		import io.swagger.annotations.ApiOperation;
		«ENDIF»
		«entity.imports.map[it].join('\r\n')»
		
		@RestController
		@RequestMapping("«service.domain»/«service.name»/entities/«entityDTOVar»")
		«IF isEnableDoc»
		@Api(value = "«entityDTOName»", tags = {"«entityDTOName»"}, description = "Operations for «title»")
		«ENDIF»
		public class «entity.toControllerName» {
			
			@Autowired
			private «entity.toServiceName» «entityServiceVar»;
			
			@Autowired
			«entityDTOName»DTOConverter «entityDTOVar»DTOConverter;
			«IF !ruleFormActionsWithFunction.isEmpty»
			
			@Autowired
			private «entity.toRuleFormActionsWithFunctionName» «entity.toRuleFormActionsWithFunctionName.toFirstLower»;
			«ENDIF»
			
			@Transactional
			@PostMapping
			«IF isEnableDoc»
			@ApiOperation(value = "Creates a new «title»")
			«ENDIF»
			public ResponseEntity<«entityDTOName»> create(@Valid @RequestBody «entityDTOName» «entityDTOVar») {
				«entityName» «entityVar» = «entityServiceVar».create(«entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
				return ResponseEntity.status(HttpStatus.CREATED).body(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
			}
			
			@Transactional(readOnly = true)
			@GetMapping("/{«idVar»}")
			«IF isEnableDoc»
			@ApiOperation(value = "Retrieves «title»")
			«ENDIF»
			public ResponseEntity<«entityDTOName»> read(@PathVariable «idType» «idVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».read(«idVar»);
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@Transactional
			@PutMapping("/{«idVar»}")
			«IF isEnableDoc»
			@ApiOperation(value = "Updates «title»")
			«ENDIF»
			public ResponseEntity<«entityDTOName»> update(@PathVariable «idType» «idVar», @Valid @RequestBody «entityDTOName» «entityDTOVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».update(«idVar», «entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@ResponseStatus(HttpStatus.NO_CONTENT)
			@DeleteMapping("/{«idVar»}")
			«IF isEnableDoc»
			@ApiOperation(value = "Deletes «title»")
			«ENDIF»
			public void delete(@PathVariable «idType» «idVar») {
				«entityServiceVar».delete(«idVar»);
			}
			
			@Transactional(readOnly = true)
			@GetMapping
			«IF isEnableDoc»
			@ApiOperation(value = "Retrieves a list of «title»")
			«ENDIF»
			public PageResult<«entityDTOName»> list(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName.toFirstLower», Pageable pageable) {
				Page<«entityName»> page = «entityServiceVar».list(«entity.toEntityListFilterName.toFirstLower», pageable);
				List<«entityDTOName»> content = page.getContent().stream().map(pe -> «entityDTOVar»DTOConverter.«toDTO»(pe)).collect(Collectors.toList());
				PageResult<«entityDTOName»> pageResult = new PageResult<>(content, page.getNumber(), page.getSize(), page.getTotalElements());
				return pageResult;
			}
			
			«IF entity.hasAutoComplete»
			@Transactional(readOnly = true)
			@GetMapping("/autoComplete")
			«IF isEnableDoc»
			@ApiOperation(value = "Retrieves a list of «title» with a query param")
			«ENDIF»
			public Collection<«entity.toAutoCompleteName»> autoComplete(@RequestParam("query") String query) {
				Collection<«entity.toAutoCompleteName»> result = «entityServiceVar».autoComplete(query);
				return result;
			}
			«ENDIF»
			
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
			
			«IF entity.hasSumFields»
			«entity.generateMethodGetContaPagarSumFields»
			«ENDIF»
			
			«ruleActions.map[generateRuleActions].join»
			«ruleMakeCopies.map[generateRuleMakeCopies].join»
			«ruleFormActionsWithFunction.map[generateRuleFormActionsWithFunction].join('\r\n')»
			«IF !fkSlots.empty»
			// Begin relationships autoComplete 
			«fkSlots.map[it.generateSlotAutoCompleteMethod].join»
			// End relationships autoComplete
			
			«ENDIF»
			«IF !findBySlots.isEmpty»
						
			// findBy methods
			«findBySlotsContent»
			«ENDIF»
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
		val findByMethodCall = findByObj.generateRepositoryFindByMethod(false, true)
		
		val slot = findByObj.ownerSlot
		val ownerEntity = slot.ownerEntity
		
		val isEnableDoc = ownerEntity.service.isEnableDoc
		val title = ownerEntity.title
		
		val by = if (slot.isEntity) slot.asEntity.title else slot.name
		val entityDTOName = ownerEntity.toEntityDTOName
		val entityName = ownerEntity.toEntityName
		
		
		val entityDTOVar = ownerEntity.toEntityDTOName.toFirstLower
		val entityServiceVar = ownerEntity.toServiceName.toFirstLower
		val toDTO = 'convertEntityToDto'
		val isPaged = findByObj.isPaged
		val collectionType = if (isPaged) 'Page' else 'Collection'
		
		val isEntity = slot.isEntity
		val isManyTo = isEntity && (slot.isManyToOne || slot.isManyToMany)
		
		'''
		
		@Transactional(readOnly = true)
		@GetMapping("/«findByMethodCall.substring(0, findByMethodCall.indexOf('('))»")
		«IF isEnableDoc»
		@ApiOperation(value = "Retrieves «IF isManyTo»collection of «ENDIF»«title» by «by»")
		«ENDIF»
		«IF isManyTo»
		public «findByMethod.replace('Page<', 'PageResult<').replace(entityName, entityDTOName)» {
			«collectionType»<«entityName»> content = «entityServiceVar».«findByMethodCall»;
			List<«entityDTOName»> result = content«IF isPaged».getContent()«ENDIF».stream().map(it -> «entityDTOVar»DTOConverter.«toDTO»(it)).collect(Collectors.toList());
			«IF isPaged»
			PageResult<«entityDTOName»> pageResult = new PageResult<>(result, content.getNumber(), content.getSize(), content.getTotalElements());
			return pageResult;
			«ELSE»
			return result;
			«ENDIF»
		}
		«ELSE»
		public «findByMethod.replace(entityName, 'ResponseEntity<' + entityDTOName + '>')» {
			«entityName» content = «entityServiceVar».«findByMethodCall»;
			return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(content));
		}
		«ENDIF»
		'''
	}
	
	def CharSequence generateSlotAutoCompleteMethod(Slot slot) {
		val entity = slot.asEntity
		val ownerEntity = slot.ownerEntity
		val entityDTOName = ownerEntity.toEntityDTOName
		val entityDTOVar = ownerEntity.toEntityDTOName.toFirstLower
		
		val slotAutoCompleteName = slot.toSlotAutoCompleteName
		val entityServiceVar = slot.ownerEntity.toServiceName.toFirstLower
		val hasAutoCompleteWithOwnerParams = slot.isAutoCompleteWithOwnerParams
		
		val isEnableDoc = entity.service.isEnableDoc
		
		'''
		
		@Transactional(readOnly = true)
		«IF hasAutoCompleteWithOwnerParams»
		@PostMapping(value = "/«slotAutoCompleteName»", params = { "query" })
		«ELSE»
		@GetMapping("/«slotAutoCompleteName»")
		«ENDIF»
		«IF isEnableDoc»
		@ApiOperation(value = "Retrieves a list of «entity.toAutoCompleteName» by query «slotAutoCompleteName» over «entityDTOName» with a query param")
		«ENDIF»
		public Collection<«entity.toAutoCompleteName»> «slotAutoCompleteName»(@RequestParam("query") String query«IF hasAutoCompleteWithOwnerParams», @RequestBody «entityDTOName» «entityDTOVar»«ENDIF») {
			Collection<«entity.toAutoCompleteName»> result = «entityServiceVar».«slotAutoCompleteName»(query«IF hasAutoCompleteWithOwnerParams», «entityDTOVar»«ENDIF»);
			return result;
		}
		
		'''
	}
	
	def CharSequence generateRuleFormActionsWithFunction(Rule rule) {
		val entity = (rule.owner as Entity)
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		
		val toDTO = 'convertEntityToDto'
		
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		val function = rule.apply.ruleFunction
		val isFuncReturnThis = function.funcReturnThis
		val isFuncParamThis = function.funcParamThis
		val methodName = entity.toEntityRuleFormActionsFunctionName(function)
		val ruleFuncServiceVar = entity.toRuleFormActionsWithFunctionName.toFirstLower
		
		val isEnableDoc = entity.service.isEnableDoc
		
		'''
		@Transactional
		@PutMapping("/«methodName»/{«idVar»}")
		«IF isEnableDoc»
		@ApiOperation(value = "Executes the action «methodName» over «entityDTOName»")
		«ENDIF»
		public ResponseEntity<«entityDTOName»> «methodName»(@PathVariable «idType» «idVar», @Valid @RequestBody «entityDTOName» «entityDTOVar») {
			try {
				«IF isFuncReturnThis && isFuncParamThis»
				«entityName» «entityVar» = «ruleFuncServiceVar».«function.methodName.toFirstLower»(«idVar», «entityDTOVar»);
				return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				«ELSEIF isFuncReturnThis»
				«entityName» «entityVar» = «ruleFuncServiceVar».«function.methodName.toFirstLower»();
				return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				«ELSEIF isFuncParamThis»
				«ruleFuncServiceVar».«function.methodName.toFirstLower»(«idVar», «entityDTOVar»);
				return ResponseEntity.ok(null);
				«ELSEIF !isFuncReturnThis && !isFuncParamThis»
				«ruleFuncServiceVar».«function.methodName.toFirstLower»();
				return ResponseEntity.ok(null);
				«ENDIF»
			}
			catch(IllegalArgumentException e) {
				return ResponseEntity.notFound().build();
			}
		}
		
		'''
	}
	
	def CharSequence generateRuleMakeCopies(Rule rule) {
		val actionName = rule.getRuleActionMakeCopiesName
		val entity = (rule.owner as Entity)
		val entityServiceVar = entity.toServiceName.toFirstLower
		
		val makeCopiesClassName = entity.toEntityMakeCopiesName
		val makeCopiesNameVar = entity.toEntityMakeCopiesName.toFirstLower
		
		val isEnableDoc = entity.service.isEnableDoc
		
		'''
		
		@PostMapping("/«actionName»")
		@ResponseStatus(HttpStatus.NO_CONTENT)
		«IF isEnableDoc»
		@ApiOperation(value = "Executes the action «actionName»")
		«ENDIF»
		public void «actionName»(@Valid @RequestBody «makeCopiesClassName» «makeCopiesNameVar») {
			try {
				«entityServiceVar».«actionName»(«makeCopiesNameVar»);
			}
			catch(Exception e) {
				throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);
			}
		}
		'''
	}
	
	def CharSequence generateRuleActions(Rule rule) {
		val actionName = rule.getRuleActionName
		val entity = (rule.owner as Entity)
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val entityServiceVar = entity.toServiceName.toFirstLower
		
		val isEnableDoc = entity.service.isEnableDoc
		
		'''
		
		@PutMapping("/«actionName»/{«idVar»}")
		@ResponseStatus(HttpStatus.NO_CONTENT)
		«IF isEnableDoc»
		@ApiOperation(value = "Executes the action «actionName»")
		«ENDIF»
		public void «actionName»(@PathVariable «idType» «idVar») {
			try {
				«entityServiceVar».«actionName»(«idVar»);
			}
			catch(IllegalStateException e) {
				throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);
			}
		}
		'''
	}
	
	def CharSequence generateMethodGetContaPagarSumFields(Entity entity) {
		val sumFieldsName = entity.toEntitySumFieldsName
		val getEntitySumFields = 'get' + sumFieldsName
		val entityServiceVar = entity.toServiceName.toFirstLower
		val listFilterName = entity.toEntityListFilterName
		
		val isEnableDoc = entity.service.isEnableDoc
		
		'''
		@GetMapping("/«sumFieldsName.toFirstLower»")
		«IF isEnableDoc»
		@ApiOperation(value = "Retrieves a sum of «sumFieldsName.toFirstLower» filtering by «listFilterName»")
		«ENDIF»
		public «entity.toEntitySumFieldsName» «getEntitySumFields»(«entity.toEntityListFilterClassName» «listFilterName») {
			«sumFieldsName» result = «entityServiceVar».«getEntitySumFields»(«listFilterName»);
			return result;
		}
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val entity = slot.ownerEntity
		val isEnableDoc = entity.service.isEnableDoc
		val title = entity.title
		
		'''
		
		@GetMapping("/«autoComplateName»")
		«IF isEnableDoc»
		@ApiOperation(value = "Retrieves a list of «title» with a query param")
		«ENDIF»
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(@RequestParam("query") String query) {
			Collection<«autoComplateName.toFirstUpper»> result = «slot.ownerEntity.toServiceName.toFirstLower».«autoComplateName»(query);
			return result;
		}
		'''
	}
	
}