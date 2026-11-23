// Security-rules tests: owner vs staff vs deactivated vs unauthenticated.
// Run with `npm run test:emulator` (needs Java 11+ for the emulator).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-tindascan';
const OWNER = 'owner-uid';
const STAFF = 'staff-uid';
const STAFF2 = 'staff2-uid';
const INACTIVE = 'inactive-uid';
const PRODUCT = 'prod-1';
const BARCODE = '4800016644283';

let env;

const userDoc = (name, role, active = true) => ({
  name,
  email: `${name.toLowerCase()}@example.com`,
  role,
  active,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
});

const productDoc = (overrides = {}) => ({
  barcode: BARCODE,
  name: 'Lucky Me Pancit Canton',
  nameLower: 'lucky me pancit canton',
  keywords: ['l', 'lu', 'luc', 'lucky', 'm', 'me', 'p', 'pa', 'pan', 'pancit'],
  category: 'noodles',
  unitPriceCentavos: 1600,
  costPriceCentavos: 1250,
  stockQty: 20,
  lowStockThreshold: 5,
  lowStock: false,
  expiryDate: null,
  isActive: true,
  hasBarcode: true,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  ...overrides,
});

const saleDoc = (cashierId, overrides = {}) => ({
  receiptNo: '20261119-0001',
  items: [
    {
      productId: PRODUCT,
      barcode: BARCODE,
      name: 'Lucky Me Pancit Canton',
      qty: 2,
      unitPriceCentavos: 1600,
      costPriceCentavos: 1250,
      subtotalCentavos: 3200,
    },
  ],
  itemCount: 2,
  totalCentavos: 3200,
  costTotalCentavos: 2500,
  amountTenderedCentavos: 5000,
  changeCentavos: 1800,
  cashierId,
  cashierName: 'Staff',
  createdAt: serverTimestamp(),
  dayKey: '20261119',
  offline: false,
  ...overrides,
});

const db = (uid) =>
  uid
    ? env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore()
    : env.unauthenticatedContext().firestore();

async function seed({ withSetup = true } = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const admin = ctx.firestore();
    if (withSetup) {
      await setDoc(doc(admin, 'settings/setup'), { completed: true, completedAt: Timestamp.now() });
      await setDoc(doc(admin, 'settings/store'), {
        storeName: 'Aling Nena Store',
        defaultLowStockThreshold: 5,
        updatedAt: Timestamp.now(),
      });
      await setDoc(doc(admin, `users/${OWNER}`), userDoc('Owner', 'owner'));
      await setDoc(doc(admin, `users/${STAFF}`), userDoc('Staff', 'staff'));
      await setDoc(doc(admin, `users/${STAFF2}`), userDoc('Staff2', 'staff'));
      await setDoc(doc(admin, `users/${INACTIVE}`), userDoc('Inactive', 'staff', false));
      await setDoc(doc(admin, `products/${PRODUCT}`), productDoc());
      await setDoc(doc(admin, `barcodes/${BARCODE}`), { productId: PRODUCT });
      await setDoc(doc(admin, 'sales/existing-sale'), {
        ...saleDoc(STAFF2),
        createdAt: Timestamp.now(),
      });
      await setDoc(doc(admin, 'daily_stats/20261119'), {
        salesCentavos: 1000,
        costCentavos: 800,
        transactionCount: 1,
        itemsSold: 1,
        products: {},
        lastSaleId: 'existing-sale',
        updatedAt: Timestamp.now(),
      });
    }
  });
}

/** Adds the receipt counter and daily stats writes of an online checkout. */
function withCounterAndStats(firestore, batch, saleId) {
  batch.set(doc(firestore, 'counters/receipts_20261120'), { seq: 1, lastSaleId: saleId });
  batch.set(
    doc(firestore, 'daily_stats/20261120'),
    {
      salesCentavos: increment(3200),
      costCentavos: increment(2500),
      transactionCount: increment(1),
      itemsSold: increment(2),
      products: {
        [PRODUCT]: { name: 'Lucky Me Pancit Canton', qty: increment(2), salesCentavos: increment(3200) },
      },
      lastSaleId: saleId,
      updatedAt: serverTimestamp(),
    },
    { merge: true },
  );
  return batch;
}

/** Builds the batch a checkout performs for `uid` selling 2 units. */
function saleBatch(firestore, uid, { saleId = 'sale-new', cashierId = uid } = {}) {
  const batch = writeBatch(firestore);
  batch.set(doc(firestore, `sales/${saleId}`), saleDoc(cashierId));
  batch.update(doc(firestore, `products/${PRODUCT}`), {
    stockQty: 18,
    lowStock: false,
    updatedAt: serverTimestamp(),
    lastSaleId: saleId,
  });
  batch.set(doc(firestore, `stock_movements/${saleId}_${PRODUCT}`), {
    productId: PRODUCT,
    productName: 'Lucky Me Pancit Canton',
    type: 'sale',
    qtyChange: -2,
    note: '',
    userId: uid,
    userName: 'Staff',
    saleId,
    createdAt: serverTimestamp(),
  });
  return batch;
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

describe('first-run owner setup', () => {
  beforeEach(async () => {
    await env.clearFirestore();
  });

  const setupBatch = (firestore, uid) => {
    const batch = writeBatch(firestore);
    batch.set(doc(firestore, `users/${uid}`), {
      name: 'New Owner',
      email: `${uid}@example.com`,
      role: 'owner',
      active: true,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    batch.set(doc(firestore, 'settings/store'), {
      storeName: 'My Store',
      defaultLowStockThreshold: 5,
      updatedAt: serverTimestamp(),
    });
    batch.set(doc(firestore, 'settings/setup'), {
      completed: true,
      completedAt: serverTimestamp(),
    });
    return batch;
  };

  it('anyone can read the setup flag', async () => {
    await assertSucceeds(getDoc(doc(db(null), 'settings/setup')));
  });

  it('the first user can register as owner exactly once', async () => {
    await assertSucceeds(setupBatch(db('first'), 'first').commit());
    await assertFails(setupBatch(db('second'), 'second').commit());
  });

  it('cannot self-register as owner without the setup flag', async () => {
    await assertFails(
      setDoc(doc(db('sneaky'), 'users/sneaky'), {
        name: 'Sneaky',
        email: 'sneaky@example.com',
        role: 'owner',
        active: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

describe('with a configured store', () => {
  beforeEach(async () => {
    await env.clearFirestore();
    await seed();
  });

  describe('unauthenticated', () => {
    it('cannot read products, users or sales', async () => {
      const anon = db(null);
      await assertFails(getDoc(doc(anon, `products/${PRODUCT}`)));
      await assertFails(getDoc(doc(anon, `users/${OWNER}`)));
      await assertFails(getDoc(doc(anon, 'sales/existing-sale')));
      await assertFails(getDoc(doc(anon, 'settings/store')));
    });
  });

  describe('users', () => {
    it('owner can list users and create staff', async () => {
      const owner = db(OWNER);
      await assertSucceeds(getDocs(collection(owner, 'users')));
      await assertSucceeds(
        setDoc(doc(owner, 'users/new-staff'), {
          name: 'New Staff',
          email: 'newstaff@example.com',
          role: 'staff',
          active: true,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('owner cannot create another owner', async () => {
      await assertFails(
        setDoc(doc(db(OWNER), 'users/owner2'), {
          name: 'Owner Two',
          email: 'o2@example.com',
          role: 'owner',
          active: true,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('staff cannot manage users or change their own role', async () => {
      const staff = db(STAFF);
      await assertFails(getDocs(collection(staff, 'users')));
      await assertFails(getDoc(doc(staff, `users/${OWNER}`)));
      await assertSucceeds(getDoc(doc(staff, `users/${STAFF}`)));
      await assertFails(
        updateDoc(doc(staff, `users/${STAFF}`), { role: 'owner', updatedAt: serverTimestamp() }),
      );
      await assertFails(
        updateDoc(doc(staff, `users/${STAFF2}`), { active: false, updatedAt: serverTimestamp() }),
      );
      await assertSucceeds(
        updateDoc(doc(staff, `users/${STAFF}`), { name: 'Renamed', updatedAt: serverTimestamp() }),
      );
    });

    it('owner can deactivate staff but not itself', async () => {
      const owner = db(OWNER);
      await assertSucceeds(
        updateDoc(doc(owner, `users/${STAFF}`), { active: false, updatedAt: serverTimestamp() }),
      );
      await assertFails(
        updateDoc(doc(owner, `users/${OWNER}`), { active: false, updatedAt: serverTimestamp() }),
      );
    });

    it('nobody can delete users', async () => {
      await assertFails(deleteDoc(doc(db(OWNER), `users/${STAFF}`)));
    });
  });

  describe('deactivated staff', () => {
    it('is blocked everywhere except reading their own profile', async () => {
      const inactive = db(INACTIVE);
      await assertSucceeds(getDoc(doc(inactive, `users/${INACTIVE}`)));
      await assertFails(getDoc(doc(inactive, `products/${PRODUCT}`)));
      await assertFails(getDoc(doc(inactive, 'settings/store')));
      await assertFails(saleBatch(inactive, INACTIVE).commit());
    });
  });

  describe('products', () => {
    it('staff can read but not edit prices, create or delete', async () => {
      const staff = db(STAFF);
      await assertSucceeds(getDoc(doc(staff, `products/${PRODUCT}`)));
      await assertFails(
        updateDoc(doc(staff, `products/${PRODUCT}`), {
          unitPriceCentavos: 1,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(staff, `products/${PRODUCT}`), {
          stockQty: 100,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(deleteDoc(doc(staff, `products/${PRODUCT}`)));
    });

    it('staff cannot lower stock without a matching new sale', async () => {
      await assertFails(
        updateDoc(doc(db(STAFF), `products/${PRODUCT}`), {
          stockQty: 1,
          lowStock: true,
          updatedAt: serverTimestamp(),
          lastSaleId: 'existing-sale',
        }),
      );
    });

    it('owner can create a product together with its barcode claim', async () => {
      const owner = db(OWNER);
      const batch = writeBatch(owner);
      batch.set(doc(owner, 'products/prod-2'), productDoc({
        barcode: '4800194104101',
        name: 'Bear Brand 33g',
        nameLower: 'bear brand 33g',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }));
      batch.set(doc(owner, 'barcodes/4800194104101'), { productId: 'prod-2' });
      await assertSucceeds(batch.commit());
    });

    it('rejects a duplicate barcode', async () => {
      const owner = db(OWNER);
      const batch = writeBatch(owner);
      batch.set(doc(owner, 'products/prod-3'), productDoc({
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }));
      batch.set(doc(owner, `barcodes/${BARCODE}`), { productId: 'prod-3' });
      await assertFails(batch.commit());
    });

    it('rejects negative prices and mismatched nameLower', async () => {
      const owner = db(OWNER);
      await assertFails(
        updateDoc(doc(owner, `products/${PRODUCT}`), {
          unitPriceCentavos: -5,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(owner, `products/${PRODUCT}`), {
          name: 'Changed',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('owner can soft-delete but never hard-delete', async () => {
      const owner = db(OWNER);
      await assertSucceeds(
        updateDoc(doc(owner, `products/${PRODUCT}`), {
          isActive: false,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(deleteDoc(doc(owner, `products/${PRODUCT}`)));
    });
  });

  describe('sales', () => {
    it('staff can create a sale with stock decrement and movement', async () => {
      await assertSucceeds(saleBatch(db(STAFF), STAFF).commit());
    });

    it('staff checkout with receipt counter and daily stats succeeds', async () => {
      const staff = db(STAFF);
      await assertSucceeds(
        withCounterAndStats(staff, saleBatch(staff, STAFF, { saleId: 'sale-x' }), 'sale-x').commit(),
      );
    });

    it('daily stats and counters cannot be written without a sale', async () => {
      const staff = db(STAFF);
      await assertFails(
        setDoc(doc(staff, 'counters/receipts_20261120'), { seq: 1, lastSaleId: 'nope' }),
      );
      await assertFails(
        setDoc(doc(staff, 'daily_stats/20261121'), {
          salesCentavos: 999999,
          costCentavos: 0,
          transactionCount: 1,
          itemsSold: 1,
          products: {},
          lastSaleId: 'nope',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('staff may check whether a new sale id exists (idempotent retry)', async () => {
      await assertSucceeds(getDoc(doc(db(STAFF), 'sales/not-created-yet')));
    });

    it('staff cannot create a sale in someone else\'s name', async () => {
      await assertFails(
        setDoc(doc(db(STAFF), 'sales/forged'), saleDoc(STAFF2)),
      );
    });

    it('rejects a sale where tendered < total or change is wrong', async () => {
      await assertFails(
        setDoc(doc(db(STAFF), 'sales/short'), saleDoc(STAFF, {
          amountTenderedCentavos: 100,
          changeCentavos: 0,
        })),
      );
      await assertFails(
        setDoc(doc(db(STAFF), 'sales/badchange'), saleDoc(STAFF, { changeCentavos: 1 })),
      );
    });

    it('sales are immutable', async () => {
      await assertFails(
        updateDoc(doc(db(OWNER), 'sales/existing-sale'), { totalCentavos: 0 }),
      );
      await assertFails(deleteDoc(doc(db(OWNER), 'sales/existing-sale')));
    });

    it('staff read only their own sales; owner reads all', async () => {
      await assertFails(getDoc(doc(db(STAFF), 'sales/existing-sale')));
      await assertSucceeds(getDoc(doc(db(STAFF2), 'sales/existing-sale')));
      await assertSucceeds(
        getDocs(query(collection(db(STAFF), 'sales'), where('cashierId', '==', STAFF))),
      );
      await assertFails(getDocs(collection(db(STAFF), 'sales')));
      await assertSucceeds(getDocs(collection(db(OWNER), 'sales')));
    });
  });

  describe('reports data', () => {
    it('staff cannot read daily stats or stock movements', async () => {
      await assertFails(getDoc(doc(db(STAFF), 'daily_stats/20261119')));
      await assertFails(getDocs(collection(db(STAFF), 'stock_movements')));
      await assertSucceeds(getDoc(doc(db(OWNER), 'daily_stats/20261119')));
    });

    it('staff cannot write restock movements', async () => {
      await assertFails(
        setDoc(doc(db(STAFF), 'stock_movements/m1'), {
          productId: PRODUCT,
          productName: 'Lucky Me Pancit Canton',
          type: 'restock',
          qtyChange: 10,
          note: '',
          userId: STAFF,
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('owner can record a restock movement', async () => {
      await assertSucceeds(
        setDoc(doc(db(OWNER), 'stock_movements/m2'), {
          productId: PRODUCT,
          productName: 'Lucky Me Pancit Canton',
          type: 'restock',
          qtyChange: 10,
          note: 'Delivery',
          userId: OWNER,
          userName: 'Owner',
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('staff cannot edit store settings', async () => {
      await assertFails(
        updateDoc(doc(db(STAFF), 'settings/store'), {
          storeName: 'Hacked',
          updatedAt: serverTimestamp(),
        }),
      );
    });
  });
});
