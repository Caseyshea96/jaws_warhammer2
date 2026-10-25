using System;
using System.Collections.Generic;
namespace JawsPilot {
    // Native API delegates make registration lifetime independently testable.
    public sealed class HotkeyPolicy : IDisposable {
        private readonly Func<int,int,bool> register;
        private readonly Func<int,bool> unregister;
        private readonly Dictionary<int,int> desired = new Dictionary<int,int>();
        private readonly HashSet<int> owned = new HashSet<int>();
        private bool active, disposed;
        public HotkeyPolicy(Func<int,int,bool> register, Func<int,bool> unregister) {
            this.register = register; this.unregister = unregister;
        }
        public void Add(int id, int key) {
            if (active || disposed) throw new InvalidOperationException("Configure hotkeys before activation");
            desired.Add(id,key);
        }
        public bool CanDispatch(int id) { return active && !disposed && owned.Contains(id); }
        public int[] SetActive(bool value) {
            var failures = new List<int>();
            if (disposed) return failures.ToArray();
            if (!value) {
                active = false;
                foreach (int id in new List<int>(owned)) {
                    if (unregister(id)) owned.Remove(id); else failures.Add(id);
                }
            } else if (!active) {
                active = true;
                foreach (var pair in desired) {
                    if (owned.Contains(pair.Key)) continue;
                    if (register(pair.Key,pair.Value)) owned.Add(pair.Key); else failures.Add(pair.Key);
                }
            }
            return failures.ToArray();
        }
        public void Dispose() { SetActive(false); disposed=true; }
    }
}
